// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000023
// Created: 2026
// COMPONENT: Live coaching quality controls
// PURPOSE: Preserve bounded useful context and explain silence without retaining meeting content.
// RELATES: LiveSessionCoordinator, LiveCoachingInput, CueArbiter
// FLOW: Current speech -> validated candidate -> reasoned arbitration -> transient diagnostics and cleanup.

/// Couples a displayed cue or a fixed rejection reason to one serialized arbitration decision.
public enum CueDecision: Sendable, Equatable
{
    case displayed(CoachCue)
    case suppressed(CueSuppressionReason)

    public var cue: CoachCue?
    {
        if case .displayed(let cue) = self
        {
            return cue
        }
        return nil
    }

    public var suppressionReason: CueSuppressionReason?
    {
        if case .suppressed(let reason) = self
        {
            return reason
        }
        return nil
    }
}
