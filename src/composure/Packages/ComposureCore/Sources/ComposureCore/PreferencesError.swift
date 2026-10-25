// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: bd27cb97-efee-4e52-bad1-bea1d075277b
// Created: 2026
// COMPONENT: Preference error vocabulary
// PURPOSE: Explain controlled storage failures without exposing stored bytes or framework errors.
// RELATES: PreferencesStore, PreferencesCoordinator
// FLOW: Storage boundary -> fixed error -> native recovery controls.

import Foundation

/// Errors remain distinguishable from a successful first-run load.
public enum PreferencesError: String, Error, Sendable, LocalizedError
{
    case invalidStoredData = "PREFERENCES_INVALID_DATA"
    case unsupportedVersion = "PREFERENCES_UNSUPPORTED_VERSION"
    case saveFailed = "PREFERENCES_SAVE_FAILED"

    public var errorDescription: String?
    {
        switch self
        {
        case .invalidStoredData:
            return "Saved preferences could not be read. Retry, or reset saved preferences to start again."
        case .unsupportedVersion:
            return "These preferences require a newer app version. Update Composure, or reset saved preferences."
        case .saveFailed:
            return "Preferences could not be saved. Your choices remain here. Try saving again."
        }
    }
}
