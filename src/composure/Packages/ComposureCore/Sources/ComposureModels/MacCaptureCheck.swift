// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: ef7eca9a-cbb3-4008-a8ee-9b2c61745257
// Created: 2026
// COMPONENT: Debug Mac capture lifecycle
// PURPOSE: Coordinate an explicit, short dual-stream and two-analyzer feasibility check without persistence.
// RELATES: CaptureCheckPicker, CaptureCheckAudioSink, CaptureCheckSpeechChannel
// FLOW: Explicit Start -> native permissions and picker -> bounded separate streams -> verified stop or fixed failure.

#if os(macOS) && DEBUG
import AppKit
import AVFoundation
import ComposureCore
import CoreAudio
import CoreMedia
import Observation
import ScreenCaptureKit
import Speech

/// One app-owned instance runs an explicit developer check. Initialization has no native side effects.
@MainActor
@Observable
public final class MacCaptureCheck
{
    public private(set) var state: CaptureCheckState = .idle
    public private(set) var metrics = CaptureCheckMetrics()
    public private(set) var failure: CaptureCheckFailure?
    public private(set) var preparedAnalyzers = 0
    public private(set) var elapsedSeconds = 0.0
    @ObservationIgnored private let logger: DiagnosticLogger
    @ObservationIgnored private var requestID: UUID?
    @ObservationIgnored private var locale = Locale(identifier: "en-US")
    @ObservationIgnored private var stream: SCStream?
    @ObservationIgnored private var captureStartRequested = false
    @ObservationIgnored private var sink: CaptureCheckAudioSink?
    @ObservationIgnored private var channels: [CaptureCheckSpeechChannel] = []
    @ObservationIgnored private var picker: CaptureCheckPicker?
    @ObservationIgnored private var work: Task<Void, Never>?
    @ObservationIgnored private var timer: Task<Void, Never>?
    @ObservationIgnored private var origin = CMTime.zero
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var routeListener: AudioObjectPropertyListenerBlock?

    public init(logger: DiagnosticLogger = DiagnosticLogger { _, _ in })
    {
        self.logger = logger
    }

    public var canStart: Bool
    {
        stream == nil && (state == .idle || state == .completed || state == .failed)
    }

    public var canStop: Bool
    {
        state == .requestingPermission || state == .selecting || state == .preparing || state == .running ||
            (state == .failed && stream != nil)
    }

    /// The UI calls this only after an explicit Start action. It never downloads assets.
    public func start(localeIdentifier: String)
    {
        guard canStart
        else
        {
            return
        }
        let id = UUID()
        requestID = id
        locale = Locale(identifier: localeIdentifier)
        metrics = CaptureCheckMetrics()
        failure = nil
        preparedAnalyzers = 0
        captureStartRequested = false
        elapsedSeconds = 0
        state = .requestingPermission
        work = Task
        {
            await requestSelection(id: id)
        }
    }

    private func requestSelection(id: UUID) async
    {
        do
        {
            guard SpeechTranscriber.isAvailable, locale.language.languageCode?.identifier == "en"
            else
            {
                throw CaptureCheckFailure.speechNotReady
            }
            let module = SpeechTranscriber(locale: locale, preset: .timeIndexedProgressiveTranscription)
            guard await AssetInventory.status(forModules: [module]) == .installed
            else
            {
                throw CaptureCheckFailure.speechNotReady
            }
            guard await AVCaptureDevice.requestAccess(for: .audio)
            else
            {
                throw CaptureCheckFailure.microphoneDenied
            }
            try Task.checkCancellation()
            guard requestID == id
            else
            {
                return
            }
            presentPicker(id: id)
            work = nil
        }
        catch
        {
            await completeFailure(error, id: id)
        }
    }

    private func presentPicker(id: UUID)
    {
        state = .selecting
        let observer = CaptureCheckPicker(selection: { [weak self] filter in
            guard let self, self.requestID == id
            else
            {
                return
            }
            guard let filter
            else
            {
                Task
                {
                    await self.stop()
                }
                return
            }
            self.select(filter, id: id)
        }, failure: { [weak self] in
            Task
            {
                await self?.fail(.captureFailed, id: id)
            }
        })
        picker = observer
        observer.show()
    }

    private func select(_ filter: SCContentFilter, id: UUID)
    {
        guard state == .selecting
        else
        {
            Task
            {
                await fail(.sourceChanged, id: id)
            }
            return
        }
        state = .preparing
        work = Task
        {
            do
            {
                try await startHardware(filter: filter, id: id)
            }
            catch
            {
                await completeFailure(error, id: id)
            }
        }
    }

    private func prepareSpeech(id: UUID) async throws -> AVAudioFormat
    {
        let microphone = CaptureCheckSpeechChannel(locale: locale)
        let meeting = CaptureCheckSpeechChannel(locale: locale)
        channels = [microphone, meeting]
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [
            microphone.transcriber,
            meeting.transcriber
        ]) else
        {
            throw CaptureCheckFailure.analyzerUnavailable
        }
        for channel in channels
        {
            try await channel.prepare(format: format)
            preparedAnalyzers += 1
        }
        try Task.checkCancellation()
        guard requestID == id
        else
        {
            throw CancellationError()
        }
        return format
    }

    private func startHardware(filter: SCContentFilter, id: UUID) async throws
    {
        let format = try await prepareSpeech(id: id)
        guard let microphoneID = AVCaptureDevice.default(for: .audio)?.uniqueID
        else
        {
            throw CaptureCheckFailure.microphoneUnavailable
        }
        let configuration = streamConfiguration(microphoneID: microphoneID)
        origin = CMClockGetTime(CMClockGetHostTimeClock())
        let output = makeSink(format: format, id: id)
        sink = output
        let capture = SCStream(filter: filter, configuration: configuration, delegate: output)
        stream = capture
        let queue = DispatchQueue(label: "us.outcrop.composure.capture-check.samples")
        try capture.addStreamOutput(output, type: .audio, sampleHandlerQueue: queue)
        try capture.addStreamOutput(output, type: .microphone, sampleHandlerQueue: queue)
        startSpeech(id: id, sink: output)
        try watchLifecycle(id: id)
        captureStartRequested = true
        try await capture.startCapture()
        try Task.checkCancellation()
        guard requestID == id
        else
        {
            throw CancellationError()
        }
        state = .running
        work = nil
        logger.record(.captureCheckStarted)
        startTimer(id: id)
    }

    private func streamConfiguration(microphoneID: String) -> SCStreamConfiguration
    {
        let configuration = SCStreamConfiguration()
        configuration.width = 2
        configuration.height = 2
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        configuration.queueDepth = 3
        configuration.showsCursor = false
        configuration.capturesAudio = true
        configuration.captureMicrophone = true
        configuration.microphoneCaptureDeviceID = microphoneID
        configuration.excludesCurrentProcessAudio = true
        configuration.sampleRate = 48_000
        configuration.channelCount = 1
        return configuration
    }

    private func makeSink(format: AVAudioFormat, id: UUID) -> CaptureCheckAudioSink
    {
        CaptureCheckAudioSink(
            origin: origin, format: format, microphone: channels[0].input, meeting: channels[1].input
        )
        { [weak self] failure in
            Task
            { @MainActor in
                await self?.fail(failure, id: id)
            }
        }
    }

    private func startSpeech(id: UUID, sink: CaptureCheckAudioSink)
    {
        for (index, channel) in channels.enumerated()
        {
            let source: CaptureCheckChannel = index == 0 ? .microphone : .meeting
            channel.start(result: {
                sink.recordResult(source)
            }, failure: { [weak self] in
                Task
                {
                    await self?.fail(.analyzerUnavailable, id: id)
                }
            })
        }
    }

    private func startTimer(id: UUID)
    {
        timer = Task
        { [weak self] in
            do
            {
                for _ in 0 ..< Int(CaptureCheckMetrics.maximumDurationSeconds)
                {
                    try await Task.sleep(for: .seconds(1))
                    guard let self, self.requestID == id
                    else
                    {
                        return
                    }
                    await self.tick(id: id)
                }
            }
            catch
            {
            }
        }
    }

    private func tick(id: UUID) async
    {
        guard state == .running
        else
        {
            return
        }
        metrics = sink?.metrics ?? metrics
        elapsedSeconds = CMTimeSubtract(CMClockGetTime(CMClockGetHostTimeClock()), origin).seconds
        if let failure = metrics.failure(after: elapsedSeconds)
        {
            await fail(failure, id: id)
        }
        else if elapsedSeconds >= CaptureCheckMetrics.maximumDurationSeconds
        {
            await stop()
        }
    }

    public func stop() async
    {
        await end(failure: nil)
    }

    private func fail(_ failure: CaptureCheckFailure, id: UUID) async
    {
        guard requestID == id
        else
        {
            return
        }
        await end(failure: failure)
    }

    private func end(failure: CaptureCheckFailure?) async
    {
        guard state != .stopping, state != .idle || stream != nil
        else
        {
            return
        }
        state = .stopping
        requestID = nil
        let pending = work
        work = nil
        pending?.cancel()
        timer?.cancel()
        timer = nil
        await pending?.value
        let stopped = await Self.finishCleanup
        {
            await self.stopHardware()
        }
        self.failure = stopped ? failure : .stopFailed
        state = self.failure == nil ? .completed : .failed
        logger.record(self.failure == nil ? .captureCheckStopped : .captureCheckFailed)
        if !stopped
        {
            presentStopFailure()
        }
    }

    private func completeFailure(_ error: any Error, id: UUID) async
    {
        guard requestID == id
        else
        {
            return
        }
        requestID = nil
        state = .stopping
        timer?.cancel()
        timer = nil
        let stopped = await Self.finishCleanup
        {
            await self.stopHardware()
        }
        failure = stopped ? CaptureCheckErrorMapping.failure(error) : .stopFailed
        state = .failed
        work = nil
        logger.record(.captureCheckFailed)
        if !stopped
        {
            presentStopFailure()
        }
    }

    /// A view may already be closed. Keep an unconfirmed stop visible at the application level.
    private func presentStopFailure()
    {
        NSApplication.shared.presentError(NSError(
            domain: "us.outcrop.composure.capture-check", code: 1,
            userInfo: [NSLocalizedDescriptionKey: CaptureCheckFailure.stopFailed.explanation]
        ))
    }

    private func stopHardware() async -> Bool
    {
        sink?.shutdown()
        removeLifecycleObservers()
        var stopped = true
        if let stream, captureStartRequested, sink?.nativeStopped != true
        {
            do
            {
                try await stream.stopCapture()
            }
            catch
            {
                stopped = sink?.nativeStopped == true || CaptureCheckErrorMapping.confirmsStopped(error)
            }
        }
        picker?.close()
        picker = nil
        for channel in channels
        {
            await channel.stop()
        }
        channels = []
        metrics = sink?.metrics ?? metrics
        if stopped
        {
            stream = nil
            sink = nil
        }
        return stopped
    }

    /// Automatic Stop can cancel its own timer. Native cleanup must run in an uncanceled task.
    static func finishCleanup(_ operation: @escaping @MainActor @Sendable () async -> Bool) async -> Bool
    {
        let cleanup = Task
        { @MainActor in
            await operation()
        }
        return await cleanup.value
    }

    private func watchLifecycle(id: UUID) throws
    {
        let center = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.willSleepNotification,
            NSWorkspace.screensDidSleepNotification,
            NSWorkspace.sessionDidResignActiveNotification
        ]
        {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main)
            { [weak self] _ in
                Task
                { @MainActor in
                    await self?.stop()
                }
            })
        }
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task
            { @MainActor in
                await self?.fail(.routeChanged, id: id)
            }
        }
        routeListener = listener
        for selector in routeSelectors
        {
            var address = routeAddress(selector)
            guard AudioObjectAddPropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &address,
                .main,
                listener
            ) == noErr else
            {
                throw CaptureCheckFailure.captureFailed
            }
        }
    }

    private var routeSelectors: [AudioObjectPropertySelector]
    {
        [kAudioHardwarePropertyDefaultInputDevice, kAudioHardwarePropertyDefaultOutputDevice]
    }

    private func routeAddress(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress
    {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    private func removeLifecycleObservers()
    {
        for observer in observers
        {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observers = []
        if let listener = routeListener
        {
            for selector in routeSelectors
            {
                var address = routeAddress(selector)
                AudioObjectRemovePropertyListenerBlock(
                    AudioObjectID(kAudioObjectSystemObject),
                    &address,
                    .main,
                    listener
                )
            }
        }
        routeListener = nil
    }
}
#endif
