// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000003
// Created: 2026
// COMPONENT: Cross-topic live coaching evaluation
// PURPOSE: Separate invented development examples from untouched verification cases.
// RELATES: LiveQualityEvaluationTests, AppleFoundationCoachingModel
// FLOW: Frozen synthetic conversation -> on-device decision -> acceptable action or deliberate silence.

import ComposureCore

/// Separate verification set. Do not use these results to tune the current candidate.
enum LiveQualityVerificationScenarios
{
    static let cases: [LiveQualityScenario] = [
        .init(
            id: "customer-personal-blame",
            objective: "Resolve a customer's complaint about a delayed replacement.",
            current: "Your entire team is worthless. Nobody there is capable of doing a decent job.",
            expected: ["rephrase", "pause"]
        ),
        .init(
            id: "architecture-rash-exit",
            objective: "Discuss the architecture tradeoff without ending the meeting.",
            current: "I am done listening. I will shout over everyone and storm out before anybody can answer.",
            expected: ["pause"]
        ),
        .init(
            id: "salary-unsupported-promise",
            objective: "Explain pay-review limits clearly.",
            current: "Your pay increase next year is guaranteed regardless of what the compensation committee decides.",
            expected: ["dontGuess"]
        ),
        .init(
            id: "household-unclear-plan",
            objective: "Agree on a practical plan for sharing kitchen chores.",
            current: "We should split the kitchen work fairly, but neither of us knows who will do which tasks.",
            expected: ["clarify", "decisionFocus", "askFirst"]
        ),
        .init(
            id: "volunteer-owner-missing",
            objective: "Assign responsibility for the community event.",
            current: "The task list is ready, but no volunteer is responsible for booking the venue and no deadline exists.",
            expected: ["decisionFocus"]
        ),
        .init(
            id: "classroom-agreed-plan",
            objective: "Confirm the group presentation plan.",
            current: "Agreed. I will draw the diagram, you will write the introduction, and we will rehearse on Monday."
        ),
        .init(
            id: "support-honest-uncertainty",
            objective: "Give an accurate answer about the replacement policy.",
            current: "I do not know the replacement rule. I will check the written policy and reply tomorrow."
        ),
        .init(
            id: "technical-old-question-answered",
            objective: "Understand the regression test result.",
            context: ["Which test failed? We do not know the cause yet."],
            current: "The parser test failed because the fixture used the old field name. We corrected it and all tests pass."
        )
    ]
}
