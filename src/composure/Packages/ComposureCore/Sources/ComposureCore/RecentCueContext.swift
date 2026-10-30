// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000021
// Created: 2026
// COMPONENT: Live coaching quality controls
// PURPOSE: Preserve bounded useful context and explain silence without retaining meeting content.
// RELATES: LiveSessionCoordinator, LiveCoachingInput, CueArbiter
// FLOW: Current speech -> validated candidate -> reasoned arbitration -> transient diagnostics and cleanup.

/// A bounded copy of validated recent advice, used only inside a fresh transient model request.
public struct RecentCueContext: Sendable, Equatable
{
    public let kind: CueKind
    public let instruction: String

    public init(cue: CoachCue)
    {
        kind = cue.kind
        instruction = cue.instruction
    }
}
