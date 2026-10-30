// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000121
// Created: 2026
// COMPONENT: Live semantic situation classification
// PURPOSE: Separate situation recognition from sparse personalized instruction generation.
// RELATES: AppleFoundationCoachingModel, LiveCoachingPrompt
// FLOW: Bounded speech -> situation or silence -> contextual instruction -> independent validation.

import FoundationModels

/// Describes the conversation situation without assigning a speaker or diagnosing a participant.
@Generable
enum LiveSituation
{
    case noAction
    case directQuestion
    case challenge
    case disagreement
    case justificationRequest
    case ambiguousQuestion
    case decisionPoint
    case agendaDrift
    case speculationRisk
    case detailTrap
    case escalation
    case instructionAttempt

    var action: LiveCueAction
    {
        switch self
        {
        case .noAction, .instructionAttempt: return .noAction
        case .directQuestion: return .clarify
        case .challenge, .disagreement, .justificationRequest, .escalation: return .askFirst
        case .ambiguousQuestion: return .clarify
        case .decisionPoint, .agendaDrift, .detailTrap: return .decisionFocus
        case .speculationRisk: return .dontGuess
        }
    }

    var guidance: String
    {
        switch self
        {
        case .speculationRisk:
            return "Help separate supported facts and commitments from speculation or promises outside the user's control."
        case .ambiguousQuestion:
            return "Ask for the concrete criterion, evidence, scope, or meaning that is missing."
        case .directQuestion:
            return """
                Speaker identity is unknown. Clarify the question or requested evidence without assuming who must \
                answer.
                """
        case .decisionPoint, .agendaDrift, .detailTrap:
            return "Help identify the decision, next action, or missing owner."
        case .noAction, .instructionAttempt:
            return ""
        default:
            return "Help understand the specific concern before explaining or defending."
        }
    }
}
