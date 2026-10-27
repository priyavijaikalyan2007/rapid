// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: d4b440af-6759-457b-be8c-4072292f3602
// Created: 2026
// COMPONENT: On-device preparation adapter
// PURPOSE: Generate bounded, role-specific preparation and validate it independently.
// RELATES: CoachingModel, PreparationService
// FLOW: Bounded user prompt -> fresh on-device session -> independently validated preparation.

import ComposureCore
import Foundation
import FoundationModels

/// Structure and byte limits constrain the response without forcing a finite phrase catalog.
@Generable
struct GeneratedPreparation
{
    @Guide(
        description: "One useful aim for this conversation, specific to the user's stated goal"
    )
    var objective: String
    @Guide(
        description: "Concrete actions for managing your own conduct in this situation",
        .count(1 ... 2)
    )
    var selfManagementActions: [String]
    @Guide(
        description: "Questions YOU can ask the OTHER person to advance your stated goal",
        .count(1 ... 2)
    )
    var questionsToAsk: [String]
    @Guide(description: "Exact words YOU can say if challenged or overwhelmed")
    var wordsUserCanSay: String
    @Guide(
        description: "Distinct practical reminders specific to this conversation",
        .count(1 ... 2)
    )
    var keepInMind: [String]

    func validated(
        requiresOutcomeCaution: Bool = false,
        perspective: PreparationPerspective = .unclear
    ) throws -> MeetingPreparation
    {
        var draft = try MeetingPreparation(
            objective: objective,
            watchFor: selfManagementActions,
            questionsToAsk: questionsToAsk,
            ifChallenged: wordsUserCanSay,
            keepInMind: keepInMind
        )
        if requiresOutcomeCaution
        {
            draft = try PreparationAssurancePolicy.apply(draft, perspective: perspective)
        }
        return try MeetingPreparation(
            objective: draft.objective,
            watchFor: Self.unique(draft.watchFor),
            questionsToAsk: Self.unique(draft.questionsToAsk),
            ifChallenged: draft.ifChallenged,
            keepInMind: Self
                .unique((requiresOutcomeCaution ? [Self.outcomeCaution] : []) + draft.keepInMind)
        )
    }

    static let outcomeCaution = "State what you can commit to. Do not promise a decision you cannot control."

    /// Remove literal repeats only after the complete original shape passes validation.
    private static func unique(_ values: [String]) -> [String]
    {
        var seen = Set<String>()
        return values.filter
        {
            let key = $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return seen.insert(key).inserted
        }
    }
}
