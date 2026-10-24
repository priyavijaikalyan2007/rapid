// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 8af1caf8-75e2-451f-9cce-bfd660f98f13
// Created: 2026
// COMPONENT: Preference persistence boundary
// PURPOSE: Admit only the bounded preference model to native persistence.
// RELATES: AppPreferences, PreferencesCoordinator
// FLOW: Typed choices -> main-actor storage adapter -> accepted state or controlled error.

/// No method accepts meeting text, arbitrary keys, or arbitrary Codable values.
@MainActor
public protocol PreferencesStore
{
    func load() throws(PreferencesError) -> AppPreferences
    func save(_ preferences: AppPreferences) throws(PreferencesError)
    func reset()
}
