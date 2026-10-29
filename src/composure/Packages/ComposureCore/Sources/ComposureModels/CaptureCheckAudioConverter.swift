// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 1ac03a20-b7a2-4834-bf47-43c61cfd913f
// Created: 2026
// COMPONENT: Debug Mac capture experiment
// PURPOSE: Check separate transient audio streams with bounded processing and no recording output.
// RELATES: MacCaptureCheck, CaptureCheckMetrics
// FLOW: Explicit capture start -> bounded separate audio -> two analyzers -> metadata or controlled stop.

#if os(macOS) && DEBUG
import AVFoundation
import ComposureCore
import CoreMedia
import Speech

/// Confined to the sink's serial sample queue. Format changes require a new explicit check.
final class CaptureCheckAudioConverter
{
    static let maximumFrames: AVAudioFrameCount = 8192
    private let target: AVAudioFormat
    private var source: AVAudioFormat?
    private var converter: AVAudioConverter?
    private var firstInputStart: CMTime?
    private var lastInputEnd: CMTime?
    private var emittedFrames: Int64 = 0

    init(target: AVAudioFormat)
    {
        self.target = target
    }

    /// Anchor the resampled timeline once. Variable converter output sizes must not create timestamp gaps.
    func convert(_ input: AVAudioPCMBuffer, at start: CMTime) throws -> AnalyzerInput?
    {
        guard start.isNumeric, target.sampleRate >= 8000, target.sampleRate <= 192_000,
              target.sampleRate.rounded() == target.sampleRate
        else
        {
            throw CaptureCheckFailure.invalidTiming
        }
        if let lastInputEnd, abs(CMTimeSubtract(start, lastInputEnd).seconds) > 0.1
        {
            throw CaptureCheckFailure.invalidTiming
        }
        if firstInputStart == nil
        {
            firstInputStart = start
        }
        lastInputEnd = CMTimeAdd(start, CMTime(
            seconds: Double(input.frameLength) / input.format.sampleRate,
            preferredTimescale: 1_000_000_000
        ))
        guard let output = try convert(input), let firstInputStart
        else
        {
            return nil
        }
        let offset = CMTime(value: emittedFrames, timescale: CMTimeScale(target.sampleRate))
        emittedFrames += Int64(output.frameLength)
        return AnalyzerInput(buffer: output, bufferStartTime: CMTimeAdd(firstInputStart, offset))
    }

    func convert(_ input: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer?
    {
        guard input.frameLength <= Self.maximumFrames
        else
        {
            throw CaptureCheckFailure.bufferLimit
        }
        guard input.frameLength > 0
        else
        {
            throw CaptureCheckFailure.unsupportedFormat
        }
        if let source, source != input.format
        {
            throw CaptureCheckFailure.routeChanged
        }
        if source == nil
        {
            source = input.format
            if input.format != target
            {
                converter = AVAudioConverter(from: input.format, to: target)
                converter?.primeMethod = .none
            }
        }
        if input.format == target
        {
            return input
        }
        guard let converter
        else
        {
            throw CaptureCheckFailure.unsupportedFormat
        }
        return try resample(input, with: converter)
    }

    private func resample(_ input: AVAudioPCMBuffer, with converter: AVAudioConverter) throws -> AVAudioPCMBuffer?
    {
        let frames = ceil(Double(input.frameLength) * target.sampleRate / input.format.sampleRate) + 32
        guard frames > 0, frames <= Double(Self.maximumFrames),
              let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: AVAudioFrameCount(frames))
        else
        {
            throw CaptureCheckFailure.bufferLimit
        }
        var supplied = false
        var failure: NSError?
        let status = converter.convert(to: output, error: &failure)
        { _, state in
            guard !supplied
            else
            {
                state.pointee = .noDataNow
                return nil
            }
            supplied = true
            state.pointee = .haveData
            return input
        }
        guard status != .error, failure == nil
        else
        {
            throw CaptureCheckFailure.unsupportedFormat
        }
        return output.frameLength > 0 ? output : nil
    }
}
#endif
