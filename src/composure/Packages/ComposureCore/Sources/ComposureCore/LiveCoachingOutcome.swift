// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000025
// Created: 2026
// COMPONENT: Live coaching quality controls
// PURPOSE: Preserve bounded useful context and explain silence without retaining meeting content.
// RELATES: LiveSessionCoordinator, LiveCoachingInput, CueArbiter
// FLOW: Current speech -> validated candidate -> reasoned arbitration -> transient diagnostics and cleanup.

/// Reports operational state without keeping a prompt, result text, or inferred participant trait.
public enum LiveCoachingOutcome: Sendable, Equatable
{
    case notListening
    case waitingForSpeech
    case evaluating
    case noAction
    case displayed
    case withheld(CueSuppressionReason)
    case failed

    public var explanation: String
    {
        switch self
        {
        case .notListening: return "Not listening"
        case .waitingForSpeech: return "Waiting for finalized speech"
        case .evaluating: return "Checking recent speech"
        case .noAction: return "No new action selected"
        case .displayed: return "Cue displayed"
        case .withheld(let reason): return "Withheld: " + reason.explanation
        case .failed: return "A coaching check failed"
        }
    }
}
