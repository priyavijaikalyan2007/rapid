// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000130
// Created: 2026
// COMPONENT: Live cue contract
// PURPOSE: Name the priority of semantic cues without allowing a model to request urgent replacement.
// RELATES: CoachCue, CueArbiter
// FLOW: Validated semantic candidate -> normal-priority temporary cue.

/// Semantic cues use normal priority. Speaker-dependent priority replacement belongs to a later verified slice.
public enum CuePriority: Int, Sendable
{
    case normal = 0
}
