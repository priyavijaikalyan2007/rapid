// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 53ad9a96-dc52-47d8-a1ed-4b92b4efdb1e
// Created: 2026
// COMPONENT: Live cue arbitration tests
// PURPOSE: Verify sparse validated cues and deterministic timing without a model.
// RELATES: CueArbiter, CueProposal
// FLOW: Synthetic proposal -> validation -> one temporary cue or silence.

import Foundation
import Testing
@testable import ComposureCore

struct CueArbiterTests
{
    @Test func differentUsefulAdviceCanReuseAHeadlineAfterCooldown() async throws
    {
        let arbiter = CueArbiter(profile: CoachingProfile())
        let first = try CueProposal(
            kind: .clarify,
            instruction: "Ask which leadership examples support the feedback.",
            confidence: 0.9,
            evidenceID: UUID()
        )
        let second = try CueProposal(
            kind: .clarify,
            instruction: "Ask who owns the next review and its date.",
            confidence: 0.9,
            evidenceID: UUID()
        )
        _ = await arbiter.consider(first, evidenceEnd: 10, now: 10)
        #expect(await arbiter.consider(second, evidenceEnd: 40, now: 40) != nil)
    }

    @Test func paraphrasedAdviceRemainsSuppressed() async throws
    {
        let arbiter = CueArbiter(profile: CoachingProfile())
        let first = try CueProposal(
            kind: .clarify,
            instruction: "Ask which leadership examples support the feedback.",
            confidence: 0.9,
            evidenceID: UUID()
        )
        let second = try CueProposal(
            kind: .clarify,
            instruction: "Ask for leadership examples that support this feedback.",
            confidence: 0.9,
            evidenceID: UUID()
        )
        _ = await arbiter.consider(first, evidenceEnd: 10, now: 10)
        let decision = await arbiter.decide(second, evidenceEnd: 40, now: 40)
        #expect(decision.suppressionReason == .duplicate)
    }

    @Test func behavioralPauseCanReplaceANormalCue() async throws
    {
        let arbiter = CueArbiter(profile: CoachingProfile())
        _ = await arbiter.consider(try proposal(), evidenceEnd: 10, now: 10)
        let pause = try CueProposal(
            kind: .pause,
            instruction: "Pause before your next reply.",
            confidence: 0.9,
            evidenceID: UUID()
        )
        let cue = await arbiter.consider(pause, evidenceEnd: 12, now: 12)
        #expect(cue?.kind == .pause)
        #expect(cue?.priority == .high)
    }

    @Test func silenceHasAContentFreeSuppressionReason() async throws
    {
        let arbiter = CueArbiter(profile: CoachingProfile())
        _ = await arbiter.consider(try proposal(), evidenceEnd: 10, now: 10)
        let decision = await arbiter.decide(try proposal(.clarify), evidenceEnd: 22, now: 22)
        #expect(decision.suppressionReason == .cooldown)
    }

    @Test func cueLabelsAloneAreNotInstructions() throws
    {
        for text in ["CLARIFY", "DontGuess", "FOCUS THE DECISION."]
        {
            #expect(throws: LiveSessionError.invalidCue)
            {
                try CueProposal(
                    kind: text.contains("DECISION") ? .decisionFocus : .clarify,
                    instruction: text,
                    confidence: 0.9,
                    evidenceID: UUID()
                )
            }
        }
    }

    @Test func cueExpiresAfterEightSeconds() async throws
    {
        let arbiter = CueArbiter(profile: CoachingProfile())
        _ = await arbiter.consider(try proposal(), evidenceEnd: 10, now: 11)
        #expect(await arbiter.current(at: 18) != nil)
        #expect(await arbiter.current(at: 19) == nil)
    }

    @Test func cooldownRejectsDifferentCueWithoutQueueing() async throws
    {
        let arbiter = CueArbiter(profile: CoachingProfile())
        _ = await arbiter.consider(try proposal(), evidenceEnd: 10, now: 10)
        #expect(await arbiter.consider(try proposal(.clarify), evidenceEnd: 22, now: 22) == nil)
        #expect(await arbiter.current(at: 31) == nil)
    }

    @Test func sameTypeIsSuppressedForNinetySeconds() async throws
    {
        let arbiter = CueArbiter(profile: CoachingProfile())
        _ = await arbiter.consider(try proposal(), evidenceEnd: 10, now: 10)
        #expect(await arbiter.consider(try proposal(), evidenceEnd: 40, now: 40) == nil)
        #expect(await arbiter.consider(try proposal(), evidenceEnd: 100, now: 100) != nil)
    }

    @Test func staleAndFutureEvidenceAreRejected() async throws
    {
        let arbiter = CueArbiter(profile: CoachingProfile())
        #expect(await arbiter.consider(try proposal(), evidenceEnd: 1, now: 20) == nil)
        #expect(await arbiter.consider(try proposal(), evidenceEnd: 30, now: 20) == nil)
    }

    @Test func lowFrequencyProfileAllowsTwoCuesInTenMinutes() async throws
    {
        var profile = CoachingProfile()
        profile.cueFrequency = .low
        let arbiter = CueArbiter(profile: profile)
        _ = await arbiter.consider(try proposal(), evidenceEnd: 10, now: 10)
        _ = await arbiter.consider(try proposal(.clarify), evidenceEnd: 100, now: 100)
        #expect(await arbiter.consider(try proposal(.decisionFocus), evidenceEnd: 200, now: 200) == nil)
    }

    @Test func invalidLanguageAndConfidenceAreRejected() throws
    {
        for instruction in [
            "Calm down.",
            "You are being emotional.",
            "First line\nSecond line",
            "Visit https://example.test"
        ]
        {
            #expect(throws: LiveSessionError.invalidCue)
            {
                try CueProposal(kind: .askFirst, instruction: instruction, confidence: 0.9, evidenceID: UUID())
            }
        }
        #expect(throws: LiveSessionError.invalidCue)
        {
            try CueProposal(
                kind: .askFirst,
                instruction: String(repeating: "word ", count: 19),
                confidence: 0.9,
                evidenceID: UUID()
            )
        }
        #expect(throws: LiveSessionError.invalidCue)
        {
            try CueProposal(
                kind: .askFirst,
                instruction: "Ask which criteria remain unmet.",
                confidence: .nan,
                evidenceID: UUID()
            )
        }
    }

    @Test func clearRemovesCueAndTimingHistory() async throws
    {
        let arbiter = CueArbiter(profile: CoachingProfile())
        _ = await arbiter.consider(try proposal(), evidenceEnd: 10, now: 10)
        await arbiter.clear()
        #expect(await arbiter.current(at: 11) == nil)
        #expect(await arbiter.consider(try proposal(), evidenceEnd: 11, now: 11) != nil)
    }

    private func proposal(_ kind: CueKind = .askFirst) throws -> CueProposal
    {
        try CueProposal(
            kind: kind,
            instruction: "Ask which criteria remain unmet.",
            confidence: 0.9,
            evidenceID: UUID()
        )
    }
}
