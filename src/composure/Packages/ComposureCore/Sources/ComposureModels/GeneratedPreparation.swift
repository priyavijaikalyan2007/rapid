// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: d4b440af-6759-457b-be8c-4072292f3602
// Created: 2026
// COMPONENT: On-device preparation adapter
// PURPOSE: Request five structured sections and validate them through the core contract.
// RELATES: CoachingModel, PreparationService
// FLOW: Bounded user prompt -> fresh on-device session -> independently validated preparation.

import ComposureCore
import FoundationModels

/// Guided generation constrains structure. Domain validation still checks every returned string.
@Generable
struct GeneratedPreparation
{
    @Guide(description: "Brief communication objective")
    var objective: String
    @Guide(description: "Behavioral habits to watch", .count(1 ... 3))
    var watchFor: [String]
    @Guide(description: "Short curious questions", .count(1 ... 3))
    var questionsToAsk: [String]
    @Guide(description: "How to respond calmly to a challenge")
    var ifChallenged: String
    @Guide(description: "Brief communication reminders", .count(1 ... 3))
    var keepInMind: [String]

    func validated() throws -> MeetingPreparation
    {
        try MeetingPreparation(
            objective: objective,
            watchFor: watchFor,
            questionsToAsk: questionsToAsk,
            ifChallenged: ifChallenged,
            keepInMind: keepInMind
        )
    }
}
