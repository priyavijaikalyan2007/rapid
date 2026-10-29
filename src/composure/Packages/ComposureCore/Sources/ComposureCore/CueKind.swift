// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000006
// Created: 2026
// COMPONENT: Transient live coaching
// PURPOSE: Bound private speech context and validate sparse actionable cues.
// RELATES: LiveSessionCoordinator, CueArbiter, ConversationBuffer
// FLOW: Explicit listening -> bounded context -> validated temporary cue -> Stop and clear.

/// A closed action vocabulary prevents model-generated diagnoses or arbitrary UI actions.
public enum CueKind: String, CaseIterable, Sendable
{
    case askFirst
    case answerDirectly
    case clarify
    case dontGuess
    case decisionFocus

    public var headline: String
    {
        switch self
        {
        case .askFirst: return "ASK FIRST"
        case .answerDirectly: return "ANSWER DIRECTLY"
        case .clarify: return "CLARIFY"
        case .dontGuess: return "DO NOT GUESS"
        case .decisionFocus: return "FOCUS THE DECISION"
        }
    }
}
