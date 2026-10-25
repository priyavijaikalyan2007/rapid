// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: da12b4d1-f46a-4989-bfb0-3d7e583a0367
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Provide useful profile-based advice without requiring model availability.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

/// Fixed behavioral advice never interprets or repeats untrusted topic instructions.
public enum FallbackPreparation
{
    public static func make(input: MeetingPreparationInput, profile: CoachingProfile) throws -> MeetingPreparation
    {
        let restrained = input.highStakes || profile.executiveRestraint
        let focus = CoachingFocus.allCases.enumerated()
            .filter
            {
                profile[$0.element].rawValue >= FocusImportance.important.rawValue
            }
            .sorted
            {
                let left = profile[$0.element].rawValue
                let right = profile[$1.element].rawValue
                return left == right ? $0.offset < $1.offset : left > right
            }
            .prefix(3).map
            {
                advice(for: $0.element)
            }
        return try MeetingPreparation(
            objective: "Clarify your intended outcome and understand the other person's perspective.",
            watchFor: focus.isEmpty ? ["Pause before you answer, and let the other person finish."] : focus,
            questionsToAsk: ["What outcome would make this conversation useful?", "What concern matters most to you?"],
            ifChallenged: "Pause, acknowledge the concern, and ask one clarifying question.",
            keepInMind: restrained ? ["Give your shortest useful answer, then wait.", "State uncertainty clearly."] :
                ["Focus on what you can control: your pace, questions, and clarity."]
        )
    }

    private static func advice(for focus: CoachingFocus) -> String
    {
        switch focus
        {
        case .respondTooQuickly: return "Pause before answering a challenge."
        case .becomeDefensive: return "Acknowledge the concern before explaining your position."
        case .overExplain: return "Give the main point first. Add detail when asked."
        case .interruptOthers: return "Let the other person finish before you respond."
        case .stateOpinionsStrongly: return "Present your view as a view, and invite another perspective."
        case .allowAgendaDrift: return "Return to the intended outcome when the discussion drifts."
        case .speculateTooMuch: return "Name what you know and what remains uncertain."
        case .needMoreCuriosity: return "Ask what concern the question is trying to resolve."
        }
    }
}
