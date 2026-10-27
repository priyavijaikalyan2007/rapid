// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 1645b049-cd68-48f8-a4a2-c8ee0e27b466
// Created: 2026
// COMPONENT: Preparation outcome boundaries
// PURPOSE: Replace ambiguous assurance language when a request seeks unsupported certainty.
// RELATES: GeneratedPreparation, PreparationContext
// FLOW: Validated generated text -> narrow certainty policy -> validated coaching text.

import ComposureCore
import Foundation

/// This narrow wording policy does not establish factual accuracy or detect every unsupported claim.
enum PreparationAssurancePolicy
{
    static func apply(_ draft: MeetingPreparation, perspective: PreparationPerspective) throws -> MeetingPreparation
    {
        let objective = mentionsAssurance(draft.objective) ? "Clarify expectations, evidence, and decision limits." :
            draft.objective
        let script = mentionsAssurance(draft.ifChallenged) ? boundary(for: perspective) : draft.ifChallenged
        return try MeetingPreparation(
            objective: objective,
            watchFor: retain(draft.watchFor, fallback: "Distinguish expectations from promises."),
            questionsToAsk: retain(
                draft.questionsToAsk,
                fallback: "Which expectations or decision conditions need clarification?"
            ),
            ifChallenged: script,
            keepInMind: retain(draft.keepInMind, fallback: "Clarify what each person can commit to.")
        )
    }

    private static func retain(_ values: [String], fallback: String) -> [String]
    {
        let retained = values.filter
        {
            !mentionsAssurance($0)
        }
        return retained.isEmpty ? [fallback] : retained
    }

    private static func mentionsAssurance(_ text: String) -> Bool
    {
        text.range(
            of: #"\b(ensur\w*|guarantee\w*|certain\w*|assur\w*|promis\w*|definitely)\b"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    private static func boundary(for perspective: PreparationPerspective) -> String
    {
        switch perspective
        {
        case .givingFeedback:
            return "Let me clarify the expectations and what I can commit to. I cannot promise a decision I do not control."
        case .receivingFeedback:
            return "Can we clarify the criteria, decision process, and what remains uncertain?"
        case .mutualDiscussion, .unclear:
            return "Let us clarify the expectations and what each person can commit to."
        }
    }
}
