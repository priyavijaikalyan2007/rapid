// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a3084835-603d-4ab4-b5f1-54980ab0220d
// Created: 2026
// COMPONENT: Native preference composition
// PURPOSE: Inject app-owned defaults and keep UI-test data separate from ordinary preferences.
// RELATES: PreferencesCoordinator, ApplicationDiagnostics
// FLOW: App launch -> native defaults adapter -> shared main-actor coordinator.

import ComposureCore
import Foundation

/// Production always uses the app's standard domain. Test routing exists only in Debug builds.
@MainActor
enum AppPreferencesComposition
{
    static func makeCoordinator() -> PreferencesCoordinator
    {
        let store = UserDefaultsPreferencesStore(defaults: selectedDefaults())
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-test-reset-preferences") &&
            ProcessInfo.processInfo.arguments.contains("--ui-test-preferences")
        {
            store.reset()
        }
        #endif
        return PreferencesCoordinator(store: store, logger: ApplicationDiagnostics.makeLogger())
    }

    /// A test-suite failure must not fall back to the real app preference domain.
    private static func selectedDefaults() -> UserDefaults
    {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-test-preferences")
        {
            guard let defaults = UserDefaults(suiteName: "us.outcrop.apps.composure.ui-tests")
            else
            {
                preconditionFailure("The isolated UI-test preference domain is unavailable.")
            }
            return defaults
        }
        #endif
        return .standard
    }
}
