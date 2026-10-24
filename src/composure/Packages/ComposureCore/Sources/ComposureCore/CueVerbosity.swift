// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4576a527-575a-452f-9848-88b3866d5f3b
// Created: 2026
// COMPONENT: Cue detail preference
// PURPOSE: Restrict live cue detail to the two concise product options.
// RELATES: CoachingProfile
// FLOW: Native picker -> fixed preference -> future cue wording policy.

/// Both choices remain subject to the instruction's eighteen-word hard limit.
public enum CueVerbosity: String, Codable, CaseIterable, Sendable
{
    case veryShort = "Very short"
    case short = "Short"
}
