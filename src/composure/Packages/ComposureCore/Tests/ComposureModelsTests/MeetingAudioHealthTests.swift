// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000051
// Created: 2026
// COMPONENT: Native live coaching boundary tests
// PURPOSE: Verify precise timing, bounded resources, and untrusted model boundaries using synthetic data.
// RELATES: MacMeetingAudioSource, LiveCoachingPrompt, GeneratedLiveCue
// FLOW: Synthetic boundary input -> independent validation -> safe event, cue, or fixed failure.

#if os(macOS)
import ComposureCore
import Testing
@testable import ComposureModels

struct MeetingAudioHealthTests
{
    @Test func separateMicrophoneIsRequired() throws
    {
        var health = MeetingAudioHealth()
        try health.record(.meeting, start: 2.9, duration: 0.02)
        #expect(health.failure(after: 3.1) == .microphoneUnavailable)
    }

    @Test func meetingAudioIsRequired() throws
    {
        var health = MeetingAudioHealth()
        try health.record(.microphone, start: 5, duration: 0.02)
        #expect(health.failure(after: 5.1) == .meetingAudioUnavailable)
    }

    @Test func longSessionsDoNotExhaustACumulativeBufferQuota() throws
    {
        var health = MeetingAudioHealth()
        for index in 0 ..< 200_000
        {
            let stamp = Double(index) * 0.02
            try health.record(.microphone, start: stamp, duration: 0.02)
            try health.record(.meeting, start: stamp, duration: 0.02)
        }
        #expect(health.failure(after: 4000) == nil)
    }

    @Test func invalidAndReversedTimingAreRejected() throws
    {
        var health = MeetingAudioHealth()
        try health.record(.microphone, start: 2, duration: 0.02)
        #expect(throws: CaptureCheckFailure.invalidTiming)
        {
            try health.record(.microphone, start: 1, duration: 0.02)
        }
        #expect(throws: CaptureCheckFailure.invalidTiming)
        {
            try health.record(.meeting, start: .nan, duration: 0.02)
        }
    }
}
#endif
