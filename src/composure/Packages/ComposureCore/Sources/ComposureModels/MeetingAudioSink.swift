// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000082
// Created: 2026
// COMPONENT: Mac live audio capture
// PURPOSE: Stream separate bounded audio into ephemeral on-device speech with explicit cleanup.
// RELATES: LiveSessionCoordinator, MacMeetingAudioSource, MeetingSpeechChannel
// FLOW: Explicit Start and picker -> transient audio -> two analyzers -> confirmed Stop.

#if os(macOS)
import AVFoundation
import ComposureCore
import CoreMedia
import os
import ScreenCaptureKit
import Speech

/// One serial sample queue owns the converters. The lock protects bounded health and shutdown state.
final class MeetingAudioSink: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable
{
    private struct State
    {
        var health = MeetingAudioHealth()
        var active = true
        var failed = false
        var nativeStopped = false
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let origin: CMTime
    private let microphone: AsyncStream<AnalyzerInput>.Continuation
    private let meeting: AsyncStream<AnalyzerInput>.Continuation
    private let microphoneConverter: CaptureCheckAudioConverter
    private let meetingConverter: CaptureCheckAudioConverter
    private let failure: @Sendable (CaptureCheckFailure) -> Void

    init(
        origin: CMTime, format: AVAudioFormat,
        microphone: AsyncStream<AnalyzerInput>.Continuation, meeting: AsyncStream<AnalyzerInput>.Continuation,
        failure: @escaping @Sendable (CaptureCheckFailure) -> Void
    )
    {
        self.origin = origin
        self.microphone = microphone
        self.meeting = meeting
        self.failure = failure
        microphoneConverter = CaptureCheckAudioConverter(target: format)
        meetingConverter = CaptureCheckAudioConverter(target: format)
    }

    var nativeStopped: Bool
    {
        state.withLock
        {
            $0.nativeStopped
        }
    }

    func check(elapsed: Double) -> CaptureCheckFailure?
    {
        state.withLock
        {
            $0.health.failure(after: elapsed)
        }
    }

    func shutdown()
    {
        state.withLock
        {
            $0.active = false
        }
        microphone.finish()
        meeting.finish()
    }

    func stream(_ stream: SCStream, didStopWithError error: any Error)
    {
        state.withLock
        {
            $0.nativeStopped = true
        }
        fail(CaptureCheckErrorMapping.failure(error))
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sample: CMSampleBuffer, of type: SCStreamOutputType)
    {
        guard state.withLock({
            $0.active && !$0.failed
        }), CMSampleBufferDataIsReady(sample) else
        {
            return
        }
        let channel: ComposureCore.SpeechChannel
        switch type
        {
        case .audio: channel = .meeting
        case .microphone: channel = .microphone
        default: return
        }
        do
        {
            try deliver(sample, stream: stream, channel: channel)
        }
        catch
        {
            fail(error as? CaptureCheckFailure ?? .captureFailed)
        }
    }

    private func deliver(_ sample: CMSampleBuffer, stream: SCStream, channel: ComposureCore.SpeechChannel) throws
    {
        guard let clock = stream.synchronizationClock
        else
        {
            throw CaptureCheckFailure.invalidTiming
        }
        let stamp = CMSyncConvertTime(
            CMSampleBufferGetPresentationTimeStamp(sample),
            from: clock,
            to: CMClockGetHostTimeClock()
        )
        let relative = CMTimeSubtract(stamp, origin)
        guard relative.isNumeric
        else
        {
            throw CaptureCheckFailure.invalidTiming
        }
        if relative.seconds < 0 && relative.seconds >= -0.1
        {
            return
        }
        let source = try CaptureCheckAudioSink.copyPCM(sample)
        let converter = channel == .microphone ? microphoneConverter : meetingConverter
        guard let input = try converter.convert(source, at: relative)
        else
        {
            return
        }
        let duration = Double(source.frameLength) / source.format.sampleRate
        try state.withLock
        {
            try $0.health.record(channel, start: relative.seconds, duration: duration)
        }
        guard state.withLock({
            $0.active
        }) else
        {
            return
        }
        let result = (channel == .microphone ? microphone : meeting).yield(input)
        if case .dropped = result
        {
            throw CaptureCheckFailure.bufferLimit
        }
        if case .terminated = result
        {
            throw CaptureCheckFailure.analyzerUnavailable
        }
    }

    private func fail(_ error: CaptureCheckFailure)
    {
        let notify = state.withLock
        {
            guard $0.active && !$0.failed
            else
            {
                return false
            }
            $0.failed = true
            return true
        }
        if notify
        {
            failure(error)
        }
    }
}
#endif
