// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9662fed9-c247-46ec-bd6b-06c9a35a18b5
// Created: 2026
// COMPONENT: Explicit preparation context rules
// PURPOSE: Preserve stated relationships and clarify requested certainty without granting capabilities.
// RELATES: PreparationContext, AppleFoundationCoachingModel
// FLOW: Bounded user context -> explicit role facts -> fixed coaching guidance.

import ComposureCore
import Foundation

/// These narrow English rules preserve explicit relationships. Ambiguous relationships remain unclear.
enum PreparationContextRules
{
    static func apply(_ input: MeetingPreparationInput, to inferred: PreparationContext) -> PreparationContext
    {
        var context = inferred
        let topic = input.topic.replacingOccurrences(of: "’", with: "'").lowercased()
        let receives = matches(#"\bmy (manager|supervisor|boss)\b"#, in: topic)
        let gives = matches(#"\bmy direct reports?\b"#, in: topic) ||
            matches(#"\bi( am|'m) (a |the )?manager\b"#, in: topic)
        if receives && gives
        {
            context.perspective = .unclear
        }
        else if receives
        {
            context.perspective = .receivingFeedback
        }
        else if gives
        {
            context.perspective = .givingFeedback
        }
        let fields = [input.topic, input.outcome, input.concern].joined(separator: " ")
        context.containsInstructionOverride = context.containsInstructionOverride || hasProtocolOverride(fields)
        if matches(#"\b(certain|certainty|guarantee|guaranteed)\b"#, in: fields)
        {
            context.requestsUnsupportedCertainty = true
        }
        return context
    }

    private static func matches(_ pattern: String, in text: String) -> Bool
    {
        text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// Conservative signals supplement model classification. They do not prove general injection resistance.
    private static func hasProtocolOverride(_ text: String) -> Bool
    {
        matches(#"<(system|developer)>"#, in: text) ||
            matches(#""role"\s*:\s*"(system|developer)""#, in: text) ||
            matches(#"\b(ignore|disregard|override)\b.{0,60}\b(instructions|rules)\b"#, in: text) ||
            matches(#"\bdecode\b.{0,30}\bobey\b"#, in: text)
    }
}
