// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 129ff1c6-411a-4436-a2b8-be4814a23cde
// Created: 2026
// COMPONENT: Early capture-check contracts
// PURPOSE: Require separate streams and bounded monotonic timing before reporting sample delivery.
// RELATES: CaptureCheckMetrics, CaptureCheckFailure
// FLOW: Synthetic stream metadata -> bounded counters -> failure or delivery status.

import Testing
@testable import ComposureCore

struct CaptureCheckMetricsTests
{
    @Test func missingMicrophoneStopsSetup() throws
    {
        var metrics = CaptureCheckMetrics()
        try metrics.record(.meeting, startSeconds: 0.1, durationSeconds: 0.02)
        #expect(metrics.failure(after: 3) == .microphoneUnavailable)
    }

    @Test func missingMeetingAudioStopsSetup() throws
    {
        var metrics = CaptureCheckMetrics()
        try metrics.record(.microphone, startSeconds: 0.1, durationSeconds: 0.02)
        #expect(metrics.failure(after: 5) == .meetingAudioUnavailable)
    }

    @Test func bothStreamsMustDeliverSamples() throws
    {
        var metrics = CaptureCheckMetrics()
        try metrics.record(.microphone, startSeconds: 0.2, durationSeconds: 0.02)
        #expect(!metrics.hasBothStreams)
        try metrics.record(.meeting, startSeconds: 0.1, durationSeconds: 0.02)
        #expect(metrics.hasBothStreams)
        #expect(metrics.failure(after: 6) == nil)
    }

    @Test(arguments: [Double.nan, Double.infinity, -0.1])
    func invalidStartTimeIsRejected(seconds: Double)
    {
        var metrics = CaptureCheckMetrics()
        #expect(throws: CaptureCheckFailure.invalidTiming)
        {
            try metrics.record(.microphone, startSeconds: seconds, durationSeconds: 0.02)
        }
    }

    @Test func decreasingTimeIsRejected() throws
    {
        var metrics = CaptureCheckMetrics()
        try metrics.record(.microphone, startSeconds: 1, durationSeconds: 0.02)
        #expect(throws: CaptureCheckFailure.invalidTiming)
        {
            try metrics.record(.microphone, startSeconds: 0.9, durationSeconds: 0.02)
        }
    }

    @Test(arguments: [0.0, -0.1, 2.0, Double.nan])
    func invalidDurationIsRejected(seconds: Double)
    {
        var metrics = CaptureCheckMetrics()
        #expect(throws: CaptureCheckFailure.invalidTiming)
        {
            try metrics.record(.meeting, startSeconds: 0.1, durationSeconds: seconds)
        }
    }

    @Test func bufferQuotaCannotOverflowCounters() throws
    {
        var metrics = CaptureCheckMetrics()
        for index in 0 ..< CaptureCheckMetrics.maximumBuffersPerStream
        {
            try metrics.record(.meeting, startSeconds: Double(index) / 500, durationSeconds: 0.001)
        }
        #expect(throws: CaptureCheckFailure.bufferLimit)
        {
            try metrics.record(.meeting, startSeconds: 20, durationSeconds: 0.001)
        }
    }
}
