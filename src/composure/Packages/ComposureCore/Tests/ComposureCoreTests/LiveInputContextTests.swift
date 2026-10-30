// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000005
// Created: 2026
// COMPONENT: Current speech context tests
// PURPOSE: Verify that older context cannot replace the current evidence anchor or grow recent advice without bounds.
// RELATES: LiveCoachingInput, RecentCueContext
// FLOW: Current and older invented speech -> bounded request -> current evidence and recent advice.

import Foundation
import Testing
@testable import ComposureCore

struct LiveInputContextTests
{
    @Test func currentEvidenceUsesLatestAudioEndRatherThanArrayPosition() throws
    {
        let long = try TranscriptEvent(
            channel: .microphone,
            startSeconds: 90,
            endSeconds: 99,
            text: "The latest complete sentence.",
            isFinal: true
        )
        let earlier = try TranscriptEvent(
            channel: .meeting,
            startSeconds: 95,
            endSeconds: 97,
            text: "An earlier complete sentence.",
            isFinal: true
        )
        let input = try LiveCoachingInput(
            events: [earlier, long],
            objective: "",
            profile: CoachingProfile(),
            style: .normal,
            now: 100
        )
        #expect(input.currentEvent?.id == long.id)
        #expect(input.currentEventIndex == 0)
    }

    @Test func recentAdviceIsBoundedToFourValidatedCues() throws
    {
        let recent = (0 ..< 20).map
        {
            RecentCueContext(cue: CoachCue(
                id: UUID(),
                kind: .clarify,
                priority: .normal,
                instruction: "Ask who owns review number \($0).",
                createdAt: 0,
                expiresAt: 8
            ))
        }
        let input = try LiveCoachingInput(
            events: [],
            objective: "",
            profile: CoachingProfile(),
            style: .normal,
            now: 100,
            recentCues: recent
        )
        #expect(input.recentCues.count == 4)
        #expect(input.recentCues.first?.instruction.contains("16") == true)
    }
}
