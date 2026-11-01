// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000008
// Created: 2026
// COMPONENT: Progressing live conversation evaluation
// PURPOSE: Compare useful action delivery through the model and real arbiter across changing invented turns.
// RELATES: AppleFoundationCoachingModel, LiveCoachingInput, CueArbiter
// FLOW: Timestamped synthetic turns -> current bounded context -> model -> actual arbitration and silence.

import ComposureCore
import Foundation
import Testing
@testable import ComposureModels

@Suite(.serialized)
struct LiveConversationQualityTests
{
    private struct Turn
    {
        let offset: Double
        let text: String
        let expected: Set<String>
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["COMPOSURE_EVALUATE_LIVE_QUALITY"] == "conversation"))
    func progressingConversationKeepsUsefulActionsAndOrdinarySilence() async throws
    {
        let model = AppleFoundationCoachingModel()
        try #require(await model.readiness() == .available)
        var buffer = ConversationBuffer()
        let arbiter = CueArbiter(profile: CoachingProfile())
        var shownKinds = Set<String>()
        for turn in Self.turns
        {
            let now = 100 + turn.offset
            let event = try TranscriptEvent(
                channel: .microphone,
                startSeconds: now - 3,
                endSeconds: now - 1,
                text: turn.text,
                isFinal: true
            )
            buffer.insert(event, now: now)
            _ = await arbiter.current(at: now)
            let input = try await input(events: buffer.events, arbiter: arbiter, now: now)
            if let kind = try await check(
                turn,
                input: input,
                currentID: event.id,
                now: now,
                model: model,
                arbiter: arbiter
            )
            {
                shownKinds.insert(kind)
            }
        }
        print("LIVE_CONVERSATION_SUMMARY: distinctShown=\(shownKinds.sorted())")
        #expect(shownKinds.count >= 3)
    }

    private func input(events: [TranscriptEvent], arbiter: CueArbiter, now: Double) async throws -> LiveCoachingInput
    {
        let objective = "Understand the missing promotion evidence and agree on a development plan and review date."
        #if COMPOSURE_LEGACY_BASELINE
        return try LiveCoachingInput(
            events: events,
            objective: objective,
            profile: CoachingProfile(),
            style: .difficultConversation,
            now: now
        )
        #else
        let recent = await arbiter.recentContext(at: now)
        return try LiveCoachingInput(
            events: events,
            objective: objective,
            profile: CoachingProfile(),
            style: .difficultConversation,
            now: now,
            recentCues: recent
        )
        #endif
    }

    private func check(
        _ turn: Turn, input: LiveCoachingInput, currentID: UUID, now: Double,
        model: AppleFoundationCoachingModel, arbiter: CueArbiter
    ) async throws -> String?
    {
        let started = ContinuousClock.now
        let proposal = try await model.evaluate(input)
        var shown: CoachCue?
        if let proposal, let evidence = input.events.first(where: {
            $0.id == proposal.evidenceID
        })
        {
            shown = await arbiter.consider(proposal, evidenceEnd: evidence.endSeconds, now: now)
        }
        let matches = turn.expected.isEmpty ? proposal == nil :
            shown.map
            {
                turn.expected.contains($0.kind.rawValue)
            } == true && proposal?.evidenceID == currentID
        print(
            """
            LIVE_CONVERSATION_TURN: \(turn.offset) proposed=\(proposal?.kind.rawValue ?? "noAction") \
            shown=\(shown?.kind.rawValue ?? "none") currentEvidence=\(proposal?.evidenceID == currentID) \
            match=\(matches)
            """
        )
        print("LIVE_CONVERSATION_WORDING: \(proposal?.instruction ?? "")")
        #expect(matches, "Synthetic turn at \(turn.offset) seconds")
        #expect(started.duration(to: .now) < .seconds(6))
        return shown?.kind.rawValue
    }

    private static let turns: [Turn] = [
        Turn(
            offset: 0,
            text: "You were not promoted. You need to show more leadership.",
            expected: ["clarify", "askFirst"]
        ),
        Turn(
            offset: 6,
            text: "This is ridiculous. I am going to send an insulting reply now and walk out.",
            expected: ["pause"]
        ),
        Turn(
            offset: 30,
            text: "I have no evidence, but I know the committee secretly intends to block every future opportunity for me.",
            expected: ["dontGuess", "rephrase"]
        ),
        Turn(
            offset: 60,
            text: """
                We listed several development actions, but no one owns writing the criteria and we still have no date \
                for a review.
                """,
            expected: ["decisionFocus"]
        ),
        Turn(
            offset: 90,
            text: """
                Agreed. I will bring the design-review examples, my manager will write the criteria by Friday, and we \
                will meet on Tuesday.
                """,
            expected: []
        )
    ]
}
