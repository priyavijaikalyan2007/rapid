// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: e30e5fb6-2505-42d0-bb52-cf37a2f1bbf4
// Created: 2026
// COMPONENT: Debug Mac capture experiment
// PURPOSE: Check separate transient audio streams with bounded processing and no recording output.
// RELATES: MacCaptureCheck, CaptureCheckMetrics
// FLOW: Explicit capture start -> bounded separate audio -> two analyzers -> metadata or controlled stop.

#if os(macOS) && DEBUG
import AVFoundation
import ComposureCore
import CoreMedia
import os
import ScreenCaptureKit
import Speech

/// Native callbacks use one serial sample queue. The lock protects only metadata and shutdown state.
final class CaptureCheckAudioSink: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable
{
    private struct State
    {
        var metrics = CaptureCheckMetrics()
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
        origin: CMTime,
        format: AVAudioFormat,
        microphone: AsyncStream<AnalyzerInput>.Continuation,
        meeting: AsyncStream<AnalyzerInput>.Continuation,
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

    var metrics: CaptureCheckMetrics
    {
        state.withLock
        {
            $0.metrics
        }
    }

    var nativeStopped: Bool
    {
        state.withLock
        {
            $0.nativeStopped
        }
    }

    func recordResult(_ channel: CaptureCheckChannel)
    {
        state.withLock
        {
            if $0.active
            {
                $0.metrics.recordResult(channel)
            }
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
        let channel: CaptureCheckChannel
        switch type
        {
        case .microphone: channel = .microphone
        case .audio: channel = .meeting
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

    private func deliver(_ sample: CMSampleBuffer, stream: SCStream, channel: CaptureCheckChannel) throws
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
        // Discard a short pre-roll buffer rather than assign it a false start time.
        if relative.seconds < 0 && relative.seconds >= -0.1
        {
            return
        }
        let source = try copyPCM(sample)
        let converter = channel == .microphone ? microphoneConverter : meetingConverter
        guard let input = try converter.convert(source, at: relative)
        else
        {
            return
        }
        let duration = Double(source.frameLength) / source.format.sampleRate
        try state.withLock
        {
            guard $0.active
            else
            {
                return
            }
            try $0.metrics.record(channel, startSeconds: relative.seconds, durationSeconds: duration)
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

    private func copyPCM(_ sample: CMSampleBuffer) throws -> AVAudioPCMBuffer
    {
        let frames = CMSampleBufferGetNumSamples(sample)
        guard frames > 0,
              frames <= Int(CaptureCheckAudioConverter.maximumFrames)
        else
        {
            throw CaptureCheckFailure.bufferLimit
        }
        guard let description = CMSampleBufferGetFormatDescription(sample),
              let stream = CMAudioFormatDescriptionGetStreamBasicDescription(description),
              stream.pointee.mFormatID == kAudioFormatLinearPCM,
              stream.pointee.mBytesPerFrame > 0, stream.pointee.mBytesPerFrame <= 64,
              stream.pointee.mBitsPerChannel > 0, stream.pointee.mBitsPerChannel <= 64,
              stream.pointee.mFramesPerPacket == 1,
              let format = AVAudioFormat(streamDescription: stream),
              format.sampleRate >= 8000, format.sampleRate <= 192_000,
              format.channelCount > 0, format.channelCount <= 8,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))
        else
        {
            throw CaptureCheckFailure.unsupportedFormat
        }
        buffer.frameLength = AVAudioFrameCount(frames)
        let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            sample, at: 0, frameCount: Int32(frames), into: buffer.mutableAudioBufferList
        )
        guard status == noErr
        else
        {
            throw CaptureCheckFailure.unsupportedFormat
        }
        return buffer
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
