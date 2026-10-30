// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000061
// Created: 2026
// COMPONENT: Native live coaching adapter
// PURPOSE: Translate native speech and model results into bounded validated transient contracts.
// RELATES: MacMeetingAudioSource, LiveSessionCoordinator, AppleFoundationCoachingModel
// FLOW: Explicit listening -> native on-device processing -> validated event or brief cue.

#if os(macOS)
import ComposureCore

/// Two last-end timestamps are sufficient for any session length. No cumulative audio or counters are retained.
struct MeetingAudioHealth: Sendable
{
    private var ends: [SpeechChannel: Double] = [:]

    mutating func record(_ channel: SpeechChannel, start: Double, duration: Double) throws
    {
        guard start.isFinite, duration.isFinite, start >= 0, duration > 0, duration <= 1,
              ends[channel].map({
                  start >= $0 - 0.1
              }) ?? true
        else
        {
            throw CaptureCheckFailure.invalidTiming
        }
        ends[channel] = start + duration
    }

    func failure(after elapsed: Double) -> CaptureCheckFailure?
    {
        guard elapsed.isFinite, elapsed >= 0
        else
        {
            return .invalidTiming
        }
        if elapsed - (ends[.microphone] ?? 0) > 3
        {
            return .microphoneUnavailable
        }
        if elapsed - (ends[.meeting] ?? 0) > 5
        {
            return .meetingAudioUnavailable
        }
        return nil
    }
}
#endif
