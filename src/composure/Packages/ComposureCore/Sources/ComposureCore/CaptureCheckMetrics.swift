// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: bbfc47b4-ce8d-4c1a-8886-273ddc99ad41
// Created: 2026
// COMPONENT: Early capture experiment
// PURPOSE: Keep the developer check bounded and require distinct microphone and meeting streams.
// RELATES: MacCaptureCheck, CaptureCheckMetrics
// FLOW: Separate sample metadata -> bounded validation -> explicit activity or failure.

/// Holds bounded numeric metadata only. It never retains audio or recognition text.
public struct CaptureCheckMetrics: Sendable, Equatable
{
    public static let maximumDurationSeconds = 20.0
    public static let maximumBuffersPerStream = 10_000
    public private(set) var microphoneBuffers = 0
    public private(set) var meetingBuffers = 0
    public private(set) var microphoneResults = 0
    public private(set) var meetingResults = 0
    private var lastMicrophoneStart: Double?
    private var lastMeetingStart: Double?

    public init()
    {
    }

    public var hasBothStreams: Bool
    {
        microphoneBuffers > 0 && meetingBuffers > 0
    }

    public mutating func record(
        _ channel: CaptureCheckChannel,
        startSeconds: Double,
        durationSeconds: Double
    ) throws
    {
        let previous = channel == .microphone ? lastMicrophoneStart : lastMeetingStart
        let count = channel == .microphone ? microphoneBuffers : meetingBuffers
        guard startSeconds.isFinite, startSeconds >= 0, startSeconds <= Self.maximumDurationSeconds + 2,
              durationSeconds.isFinite, durationSeconds > 0, durationSeconds <= 1,
              previous.map({
                  startSeconds >= $0
              }) ?? true
        else
        {
            throw CaptureCheckFailure.invalidTiming
        }
        guard count < Self.maximumBuffersPerStream
        else
        {
            throw CaptureCheckFailure.bufferLimit
        }
        switch channel
        {
        case .microphone:
            microphoneBuffers += 1
            lastMicrophoneStart = startSeconds
        case .meeting:
            meetingBuffers += 1
            lastMeetingStart = startSeconds
        }
    }

    public mutating func recordResult(_ channel: CaptureCheckChannel)
    {
        switch channel
        {
        case .microphone: microphoneResults = min(Self.maximumBuffersPerStream, microphoneResults + 1)
        case .meeting: meetingResults = min(Self.maximumBuffersPerStream, meetingResults + 1)
        }
    }

    public func failure(after seconds: Double) -> CaptureCheckFailure?
    {
        guard seconds.isFinite, seconds >= 0
        else
        {
            return .invalidTiming
        }
        if seconds >= 3 && microphoneBuffers == 0
        {
            return .microphoneUnavailable
        }
        if seconds >= 5 && meetingBuffers == 0
        {
            return .meetingAudioUnavailable
        }
        return nil
    }
}
