// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000084
// Created: 2026
// COMPONENT: Mac live audio capture
// PURPOSE: Stream separate bounded audio into ephemeral on-device speech with explicit cleanup.
// RELATES: LiveSessionCoordinator, MacMeetingAudioSource, MeetingSpeechChannel
// FLOW: Explicit Start and picker -> transient audio -> two analyzers -> confirmed Stop.

#if os(macOS)
import AppKit
import AVFoundation
import ComposureCore
import CoreMedia
import ScreenCaptureKit
import Speech

/// Only explicit Start requests permission, shows the picker, or captures audio.
@MainActor
public final class MacMeetingAudioSource: LiveTranscriptionSource
{
    /// Transfer only an immutable picker result. The source never mutates the selected native filter.
    private struct SelectedSource: @unchecked Sendable
    {
        let filter: SCContentFilter
    }

    private var activeID: UUID?
    private var selection: CheckedContinuation<SelectedSource, any Error>?
    private var picker: CaptureCheckPicker?
    private var channels: [MeetingSpeechChannel] = []
    private var stream: SCStream?
    private var sink: MeetingAudioSink?
    private var startRequested = false
    private var healthTask: Task<Void, Never>?
    private let lifecycle = MeetingCaptureLifecycle()

    public init()
    {
    }

    public static func now() -> Double
    {
        CMClockGetTime(CMClockGetHostTimeClock()).seconds
    }

    public func start(
        localeIdentifier: String,
        receive: @escaping @MainActor @Sendable (TranscriptEvent) -> Void,
        failure: @escaping @MainActor @Sendable (LiveSessionError) -> Void
    ) async throws
    {
        guard stream == nil, activeID == nil
        else
        {
            throw LiveSessionError.captureFailed
        }
        let id = UUID()
        activeID = id
        let locale = Locale(identifier: localeIdentifier)
        do
        {
            try await checkSpeech(locale)
            guard await AVCaptureDevice.requestAccess(for: .audio)
            else
            {
                throw CaptureCheckFailure.microphoneDenied
            }
            try ensureActive(id)
            let filter = try await select(id: id, failure: failure)
            try ensureActive(id)
            try await capture(filter: filter, locale: locale, id: id, receive: receive, failure: failure)
        }
        catch
        {
            try Task.checkCancellation()
            if error is CancellationError
            {
                throw CancellationError()
            }
            throw Self.map(error)
        }
    }

    private func checkSpeech(_ locale: Locale) async throws
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
        try Task.checkCancellation()
    }

    private func select(
        id: UUID, failure: @escaping @MainActor @Sendable (LiveSessionError) -> Void
    ) async throws -> SCContentFilter
    {
        let selected: SelectedSource = try await withCheckedThrowingContinuation
        { continuation in
            selection = continuation
            let picker = CaptureCheckPicker(selection: { [weak self] filter in
                guard let self, self.activeID == id
                else
                {
                    return
                }
                guard self.selection != nil
                else
                {
                    failure(.sourceChanged)
                    return
                }
                guard let filter
                else
                {
                    self.resolveSelection(.failure(CancellationError()))
                    return
                }
                self.resolveSelection(.success(SelectedSource(filter: filter)))
            }, failure: { [weak self] in
                self?.resolveSelection(.failure(LiveSessionError.captureFailed))
            })
            self.picker = picker
            picker.show()
        }
        return selected.filter
    }

    private func resolveSelection(_ result: Result<SelectedSource, any Error>)
    {
        let pending = selection
        selection = nil
        pending?.resume(with: result)
    }

    private func capture(
        filter: SCContentFilter, locale: Locale, id: UUID,
        receive: @escaping @MainActor @Sendable (TranscriptEvent) -> Void,
        failure: @escaping @MainActor @Sendable (LiveSessionError) -> Void
    ) async throws
    {
        let format = try await prepare(locale: locale, id: id)
        guard let microphone = AVCaptureDevice.default(for: .audio)?.uniqueID
        else
        {
            throw CaptureCheckFailure.microphoneUnavailable
        }
        let origin = CMClockGetTime(CMClockGetHostTimeClock())
        let output = MeetingAudioSink(
            origin: origin,
            format: format,
            microphone: channels[0].input,
            meeting: channels[1].input
        )
        { error in
            Task
            { @MainActor in
                failure(Self.map(error))
            }
        }
        sink = output
        let capture = SCStream(filter: filter, configuration: configuration(microphone: microphone), delegate: output)
        stream = capture
        let queue = DispatchQueue(label: "us.outcrop.composure.live.samples")
        try capture.addStreamOutput(output, type: .audio, sampleHandlerQueue: queue)
        try capture.addStreamOutput(output, type: .microphone, sampleHandlerQueue: queue)
        channels[0].start(channel: .microphone, origin: origin, receive: receive, failure: failure)
        channels[1].start(channel: .meeting, origin: origin, receive: receive, failure: failure)
        try lifecycle.watch
        {
            failure(.routeChanged)
        }
        startRequested = true
        try await capture.startCapture()
        try ensureActive(id)
        watchHealth(origin: origin, id: id, failure: failure)
    }

    private func prepare(locale: Locale, id: UUID) async throws -> AVAudioFormat
    {
        channels = [MeetingSpeechChannel(locale: locale), MeetingSpeechChannel(locale: locale)]
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: channels.map(\.transcriber)
        ) else
        {
            throw CaptureCheckFailure.analyzerUnavailable
        }
        try ensureActive(id)
        for channel in channels
        {
            try await channel.prepare(format: format)
            try ensureActive(id)
        }
        return format
    }

    private func configuration(microphone: String) -> SCStreamConfiguration
    {
        let value = SCStreamConfiguration()
        value.width = 2
        value.height = 2
        value.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        value.queueDepth = 3
        value.showsCursor = false
        value.capturesAudio = true
        value.captureMicrophone = true
        value.microphoneCaptureDeviceID = microphone
        value.excludesCurrentProcessAudio = true
        value.sampleRate = 48_000
        value.channelCount = 1
        return value
    }

    private func watchHealth(
        origin: CMTime, id: UUID, failure: @escaping @MainActor @Sendable (LiveSessionError) -> Void
    )
    {
        healthTask = Task
        { [weak self] in
            do
            {
                while !Task.isCancelled
                {
                    try await Task.sleep(for: .seconds(1))
                    guard let self, self.activeID == id
                    else
                    {
                        return
                    }
                    if let error = self.sink?.check(elapsed: Self.now() - origin.seconds)
                    {
                        failure(Self.map(error))
                        return
                    }
                }
            }
            catch
            {
            }
        }
    }

    public func cancelStart()
    {
        activeID = nil
        sink?.shutdown()
        resolveSelection(.failure(CancellationError()))
    }

    public func stop() async -> Bool
    {
        cancelStart()
        healthTask?.cancel()
        healthTask = nil
        lifecycle.clear()
        var stopped = true
        if let stream, startRequested, sink?.nativeStopped != true
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
        if stopped
        {
            stream = nil
            sink = nil
            startRequested = false
        }
        return stopped
    }

    private func ensureActive(_ id: UUID) throws
    {
        try Task.checkCancellation()
        guard activeID == id
        else
        {
            throw CancellationError()
        }
    }

    private static func map(_ error: any Error) -> LiveSessionError
    {
        if let controlled = error as? LiveSessionError
        {
            return controlled
        }
        switch CaptureCheckErrorMapping.failure(error)
        {
        case .speechNotReady, .analyzerUnavailable: return .speechUnavailable
        case .microphoneDenied: return .microphoneDenied
        case .microphoneUnavailable: return .microphoneUnavailable
        case .meetingAudioUnavailable: return .meetingAudioUnavailable
        case .routeChanged: return .routeChanged
        case .sourceChanged: return .sourceChanged
        default: return .captureFailed
        }
    }
}
#endif
