// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 79bb76e4-b02e-439d-ae97-4373ed0801f0
// COMPONENT: Reader appearance persistence
// PURPOSE: Apply bounded appearance values and save explicit defaults.
import Foundation

extension ReaderSession
{
    func updatePreferences()
    {
        preferences.normalize()
        command(["type": "preferences", "value": dictionary(preferences)])
        checkpoint()
    }

    func saveDefaults()
    {
        preferences.normalize()
        if let data = try? JSONEncoder()
            .encode(preferences)
        {
            UserDefaults.standard.set(data, forKey: "reader-defaults")
        }
    }
}
