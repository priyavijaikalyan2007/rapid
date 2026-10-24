// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9068a824-41dc-4cd3-b265-702c975d8039
// Created: 2026
// COMPONENT: Cue frequency preference
// PURPOSE: Limit frequency customization to three supported choices.
// RELATES: CoachingProfile
// FLOW: Native picker -> fixed preference -> future arbitration configuration.

/// Relative cue frequency. Every level must retain the product's bias toward silence.
public enum CueFrequency: String, Codable, CaseIterable, Sendable
{
    case low = "Low"
    case normal = "Normal"
    case high = "High"
}
