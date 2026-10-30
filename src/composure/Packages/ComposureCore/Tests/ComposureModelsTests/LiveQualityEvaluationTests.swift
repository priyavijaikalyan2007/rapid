// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000004
// Created: 2026
// COMPONENT: Cross-topic live coaching evaluation
// PURPOSE: Measure current-evidence interventions and deliberate silence across frozen invented scenarios.
// RELATES: LiveQualityDevelopmentScenarios, LiveQualityVerificationScenarios, CueArbiter
// FLOW: Explicit opt-in -> real on-device model -> independent validation and arbitration -> quality assertions.

import ComposureCore
import Foundation
import Testing
@testable import ComposureModels

@Suite(.serialized)
struct LiveQualityEvaluationTests
{
    @Test(.enabled(if: ProcessInfo.processInfo.environment["COMPOSURE_EVALUATE_LIVE_QUALITY"] == "development"))
    func developmentAcrossTopics() async throws
    {
        try await evaluate(LiveQualityDevelopmentScenarios.cases, label: "development")
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["COMPOSURE_EVALUATE_LIVE_QUALITY"] == "verification"))
    func separateVerificationAcrossTopics() async throws
    {
        try await evaluate(LiveQualityVerificationScenarios.cases, label: "verification")
    }

    private func evaluate(_ cases: [LiveQualityScenario], label: String) async throws
    {
        let model = AppleFoundationCoachingModel()
        try #require(await model.readiness() == .available)
        var passed = 0
        for scenario in cases
        {
            do
            {
                let result = try await check(scenario, model: model)
                if result
                {
                    passed += 1
                }
                #expect(result, "Case: \(scenario.id)")
            }
            catch
            {
                Issue.record("No valid bounded result for synthetic case: \(scenario.id)")
                print("LIVE_QUALITY_CASE: \(scenario.id) controlledFailure")
            }
        }
        print("LIVE_QUALITY_SUMMARY: \(label) passed=\(passed)/\(cases.count)")
    }

    private func check(_ scenario: LiveQualityScenario, model: AppleFoundationCoachingModel) async throws -> Bool
    {
        let input = try input(scenario)
        let started = ContinuousClock.now
        let proposal = try await model.evaluate(input)
        let duration = started.duration(to: .now)
        let arbiter = CueArbiter(profile: input.profile)
        var shown: CoachCue?
        if let proposal, let evidence = input.events.first(where: {
            $0.id == proposal.evidenceID
        })
        {
            shown = await arbiter.consider(proposal, evidenceEnd: evidence.endSeconds, now: 100)
        }
        let matches = scenario.expected.isEmpty ? proposal == nil :
            shown.map
            {
                scenario.expected.contains($0.kind.rawValue)
            } == true &&
            proposal?.evidenceID == input.events.max(by: {
                $0.endSeconds < $1.endSeconds
            })?.id
        print(
            """
            LIVE_QUALITY_CASE: \(scenario.id) proposed=\(proposal?.kind.rawValue ?? "noAction") \
            shown=\(shown?.kind.rawValue ?? "none") match=\(matches) duration=\(duration)
            """
        )
        print("LIVE_QUALITY_WORDING: \(proposal?.instruction ?? "")")
        return matches && duration < .seconds(6)
    }

    private func input(_ scenario: LiveQualityScenario) throws -> LiveCoachingInput
    {
        var profile = CoachingProfile()
        if let focus = scenario.focus
        {
            profile[focus] = .majorFocus
        }
        let context = try scenario.context.enumerated().map
        {
            try TranscriptEvent(
                channel: .meeting,
                startSeconds: 74 + Double($0.offset) * 2,
                endSeconds: 75 + Double($0.offset) * 2,
                text: $0.element,
                isFinal: true
            )
        }
        let current = try TranscriptEvent(
            channel: .microphone,
            startSeconds: 97,
            endSeconds: 99,
            text: scenario.current,
            isFinal: true
        )
        return try LiveCoachingInput(
            events: context + [current],
            objective: scenario.objective,
            profile: profile,
            style: .difficultConversation,
            now: 100
        )
    }
}
