// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 7ea1ae63-3a3d-4655-8ef6-640b590ec15d
// Created: 2026
// COMPONENT: Focus importance scale
// PURPOSE: Prevent invalid profile weights at creation and decoding boundaries.
// RELATES: CoachingProfile
// FLOW: Approved choice -> integer zero through three -> profile weight.

/// A bounded importance value. It does not measure communication ability or EQ.
public enum FocusImportance: Int, Codable, CaseIterable, Sendable
{
    case notRelevant = 0
    case sometimes = 1
    case important = 2
    case majorFocus = 3
}
