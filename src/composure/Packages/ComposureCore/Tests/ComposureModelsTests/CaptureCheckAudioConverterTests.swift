// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: ac895e20-1802-4245-863a-711dc2a3c63a
// Created: 2026
// COMPONENT: Native capture-check boundaries
// PURPOSE: Verify bounded conversion and passive lifecycle without recording or requesting capture.
// RELATES: MacCaptureCheck, CaptureCheckAudioConverter
// FLOW: Synthetic PCM or idle state -> native adapter -> independent boundary assertions.

#if os(macOS) && DEBUG
import AVFoundation
import ComposureCore
@testable import ComposureModels
import CoreMedia
import Testing

struct CaptureCheckAudioConverterTests
{
    @Test func nativePCMCanBecomeAnalyzerPCM() throws
    {
        let target = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let converter = CaptureCheckAudioConverter(target: target)
        let input = try makeInput(rate: 48_000, frames: 480)
        let output = try #require(try converter.convert(input))
        #expect(output.format.sampleRate == 16_000)
        #expect(output.frameLength > 0 && output.frameLength <= 192)
    }

    @Test func aChangedNativeFormatStopsTheCheck() throws
    {
        let target = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let converter = CaptureCheckAudioConverter(target: target)
        _ = try converter.convert(makeInput(rate: 48_000, frames: 480))
        #expect(throws: CaptureCheckFailure.routeChanged)
        {
            try converter.convert(makeInput(rate: 44_100, frames: 441))
        }
    }

    @Test func largePCMIsRejectedBeforeConversion() throws
    {
        let target = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let converter = CaptureCheckAudioConverter(target: target)
        #expect(throws: CaptureCheckFailure.bufferLimit)
        {
            try converter.convert(makeInput(rate: 48_000, frames: 8193))
        }
    }

    @Test func convertedPacketsKeepAContinuousSampleTimeline() throws
    {
        let target = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let converter = CaptureCheckAudioConverter(target: target)
        let firstInput = try makeInput(rate: 48_000, frames: 480)
        let secondInput = try makeInput(rate: 48_000, frames: 480)
        let first = try #require(try converter.convert(firstInput, at: CMTime(value: 1, timescale: 1)))
        let second = try #require(try converter.convert(secondInput, at: CMTime(value: 102, timescale: 100)))
        #expect(first.bufferStartTime?.seconds == 1)
        let next = try #require(second.bufferStartTime?.seconds)
        #expect(next > 1.005 && next < 1.015)
    }

    private func makeInput(rate: Double, frames: AVAudioFrameCount) throws -> AVAudioPCMBuffer
    {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1))
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames))
        buffer.frameLength = frames
        buffer.floatChannelData?[0].update(repeating: 0, count: Int(frames))
        return buffer
    }
}
#endif
