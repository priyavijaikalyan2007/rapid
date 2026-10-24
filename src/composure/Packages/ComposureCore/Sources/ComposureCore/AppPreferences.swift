// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a37ae46c-38b4-407d-8ad1-1649137ba726
// Created: 2026
// COMPONENT: Persistent preference allowlist
// PURPOSE: Keep conversation content outside the only preference storage contract.
// RELATES: CoachingProfile, PreferencesStore
// FLOW: Typed app choices -> versioned record -> app-owned defaults key.

/// Contains only fixed preferences and completion state, without arbitrary text fields.
public struct AppPreferences: Codable, Sendable, Equatable
{
    public var profile = CoachingProfile()
    public var defaultSessionStyle: SessionStyle = .normal
    public var language: CoachingLanguage = .english
    public var hasCompletedOnboarding = false

    /// Creates the first-run choices without writing anything to storage.
    public init()
    {
    }
}
