// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000022
// Created: 2026
// COMPONENT: Live coaching quality controls
// PURPOSE: Preserve bounded useful context and explain silence without retaining meeting content.
// RELATES: LiveSessionCoordinator, LiveCoachingInput, CueArbiter
// FLOW: Current speech -> validated candidate -> reasoned arbitration -> transient diagnostics and cleanup.

/// Closed operational reasons contain no conversation text, model output, or participant data.
public enum CueSuppressionReason: String, Sendable
{
    case invalidTiming
    case staleEvidence
    case visibleCue
    case cooldown
    case duplicate
    case rateLimit
    case invalidEvidence

    public var explanation: String
    {
        switch self
        {
        case .invalidTiming: return "Invalid audio timing"
        case .staleEvidence: return "Evidence too old"
        case .visibleCue: return "A cue is still visible"
        case .cooldown: return "Cue cooldown"
        case .duplicate: return "Repeated advice"
        case .rateLimit: return "Profile frequency limit"
        case .invalidEvidence: return "Current evidence missing"
        }
    }
}
