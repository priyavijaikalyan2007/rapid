// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 1d18717e-ed41-4217-b518-02288e424e07
// Created: 2026
// COMPONENT: Feedback-giver preparation
// PURPOSE: Name the speaker and listener explicitly when generating feedback-giver coaching.
// RELATES: GeneratedPreparation, PreparationPerspective
// FLOW: Feedback-giver context -> role-specific generated fields -> shared output validation.

import ComposureCore
import FoundationModels

/// Explicit field roles reduce speaker reversal. They do not establish factual accuracy.
@Generable
struct GeneratedFeedbackPreparation
{
    @Guide(description: "My aim as the person delivering feedback, using the stated goal and time frame")
    var myConversationAim: String
    @Guide(description: "Actions to manage MY conduct while delivering feedback", .count(1 ... 2))
    var actionsForMyConduct: [String]
    @Guide(description: "Ask the listener which part of what I explained needs clarification")
    var questionToCheckUnderstanding: String
    @Guide(description: "Ask what support or next step would help the listener")
    var questionAboutSupportOrNextStep: String
    @Guide(description: "Words I say directly to YOU, the listener, if you challenge the feedback I deliver")
    var wordsISayToTheListener: String
    @Guide(description: "What I must remember as the person delivering feedback", .count(1 ... 2))
    var remindersForMe: [String]

    func validated(requiresOutcomeCaution: Bool) throws -> MeetingPreparation
    {
        try GeneratedPreparation(
            objective: myConversationAim,
            selfManagementActions: actionsForMyConduct,
            questionsToAsk: [questionToCheckUnderstanding, questionAboutSupportOrNextStep],
            wordsUserCanSay: wordsISayToTheListener,
            keepInMind: remindersForMe
        ).validated(requiresOutcomeCaution: requiresOutcomeCaution, perspective: .givingFeedback)
    }
}
