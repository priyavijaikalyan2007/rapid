// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9de8168e-0b75-454e-89d6-639529e4e81f
// Created: 2026
// COMPONENT: Synthetic role-specific preparation fixtures
// PURPOSE: Distinguish receiving a decision from delivering it without real meeting details.
// RELATES: PreparationEvaluationTests
// FLOW: Synthetic role and goal -> bounded model input -> relevance review.

import ComposureCore

/// These fictional inputs reproduce the reported role difference, without storing personal meeting text.
enum PreparationQualityScenarios
{
    static func receivingDecision() throws -> MeetingPreparationInput
    {
        try MeetingPreparationInput(
            topic: "I am an employee meeting my manager after an unsuccessful promotion review.",
            outcome: "Understand the promotion criteria and the evidence needed for a future review.",
            concern: "I find it hard to stay composed when receiving disappointing feedback.",
            highStakes: true
        )
    }

    static func deliveringDecision() throws -> MeetingPreparationInput
    {
        try MeetingPreparationInput(
            topic: "I am a manager meeting a direct report whose promotion was not approved.",
            outcome: "Agree clear expectations and evidence of progress over the next six months.",
            concern: "I want the six-month plan to make their next promotion certain.",
            highStakes: true
        )
    }
}
