// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000130
// Created: 2026
// COMPONENT: Live cue contract
// PURPOSE: Name the fixed application priority without accepting an arbitrary model urgency value.
// RELATES: CoachCue, CueArbiter
// FLOW: Validated action kind -> fixed application priority -> bounded arbitration.

/// The app assigns high priority only to the closed pause and rephrase actions.
public enum CuePriority: Int, Sendable
{
    case normal = 0
    case high = 1
}
