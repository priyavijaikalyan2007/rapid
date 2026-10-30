// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000052
// Created: 2026
// COMPONENT: Native live coaching boundary tests
// PURPOSE: Verify precise timing, bounded resources, and untrusted model boundaries using synthetic data.
// RELATES: MacMeetingAudioSource, LiveCoachingPrompt, GeneratedLiveCue
// FLOW: Synthetic boundary input -> independent validation -> safe event, cue, or fixed failure.

#if os(macOS)
import ComposureCore
import CoreMedia
import Testing
@testable import ComposureModels

struct MeetingSpeechTimingTests
{
    @Test func resultRangeMapsToSharedHostClock() throws
    {
        let range = CMTimeRange(
            start: CMTime(seconds: 2.25, preferredTimescale: 48000),
            duration: CMTime(seconds: 0.75, preferredTimescale: 48000)
        )
        let event = try MeetingSpeechTiming.event(
            range: range, origin: CMTime(seconds: 100, preferredTimescale: 48000),
            channel: .meeting, text: "Synthetic final sentence.", isFinal: true
        )
        #expect(event.startSeconds == 102.25)
        #expect(event.endSeconds == 103)
        #expect(event.speaker == .unknown)
    }

    @Test func invalidRangesNeverReceiveInventedTimestamps()
    {
        #expect(throws: LiveSessionError.invalidSpeech)
        {
            try MeetingSpeechTiming.event(
                range: .invalid,
                origin: .zero,
                channel: .microphone,
                text: "Synthetic speech.",
                isFinal: true
            )
        }
    }
}
#endif
