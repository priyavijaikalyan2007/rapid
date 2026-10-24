// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: ef256dd0-63e3-46a5-806c-f61776ce49b9
// Created: 2026
// COMPONENT: Versioned preference envelope
// PURPOSE: Reject unknown schemas before interpreting their preference fields.
// RELATES: UserDefaultsPreferencesStore, AppPreferences
// FLOW: Bounded encoded record -> schema version check -> typed preferences.

import Foundation

/// Internal storage format. Only the typed adapter can create an app preference record.
struct PreferencesRecord: Codable
{
    static let currentVersion = 1
    let version: Int
    let preferences: AppPreferences

    private enum CodingKeys: String, CodingKey
    {
        case version
        case preferences
    }

    init(preferences: AppPreferences)
    {
        version = Self.currentVersion
        self.preferences = preferences
    }

    /// Checks the envelope before decoding fields that a future version may have changed.
    init(from decoder: any Decoder) throws
    {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(Int.self, forKey: .version)
        guard version == Self.currentVersion
        else
        {
            throw PreferencesError.unsupportedVersion
        }
        preferences = try values.decode(AppPreferences.self, forKey: .preferences)
    }
}
