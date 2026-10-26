// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: d4b440af-6759-457b-be8c-4072292f3602
// Created: 2026
// COMPONENT: On-device preparation adapter
// PURPOSE: Generate contextual sections and combine them with the user's stated profile priorities.
// RELATES: CoachingModel, PreparationService
// FLOW: Bounded user prompt -> fresh on-device session -> independently validated preparation.

import ComposureCore
import FoundationModels

/// Guided generation constrains structure. Domain validation still checks every returned string.
@Generable
struct GeneratedPreparation
{
    @Guide(description: "A brief communication objective tailored to the topic and desired outcome")
    var objective: PreparationObjective
    @Guide(description: "Short questions the user can ask about facts, concerns, or priorities", .count(1 ... 2))
    var questionsToAsk: [PreparationQuestion]
    @Guide(description: "One short phrase the user can say when challenged, such as: I want to understand your concern")
    var ifChallenged: PreparationChallengeResponse
    @Guide(description: "Brief reminders about the user's stated communication priorities", .count(1 ... 2))
    var keepInMind: [PreparationReminder]

    func validated(watchFor: [String]) throws -> MeetingPreparation
    {
        try MeetingPreparation(
            objective: objective.phrase,
            watchFor: watchFor,
            questionsToAsk: questionsToAsk.map(\.phrase),
            ifChallenged: ifChallenged.phrase,
            keepInMind: keepInMind.map(\.phrase)
        )
    }
}
