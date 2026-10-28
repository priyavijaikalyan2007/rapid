// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 3786022e-f9bb-4eaa-93f7-83343ae6db93
// Created: 2026
// COMPONENT: macOS application entry point
// PURPOSE: Launch the native Composure foundation without capture or model work.
// RELATES: MacRootView, ApplicationDiagnostics
// FLOW: Application launch -> local launch event -> native window.

import ComposureCore
import SwiftUI

/// Creates the macOS shell. Later capture must require a separate explicit Start action.
@main
struct ComposureMacApp: App
{
    @State private var preferences = AppPreferencesComposition.makeCoordinator()
    @State private var preparationService = PreparationComposition.makeService()
    @State private var readiness = ReadinessComposition.makeCoordinator()
    init()
    {
        ApplicationDiagnostics.makeLogger().record(.applicationLaunched)
    }

    var body: some Scene
    {
        WindowGroup
        {
            PreferencesRootView(coordinator: preferences)
            {
                MacRootView(coordinator: preferences, preparationService: preparationService, readiness: readiness)
            }
            .frame(minWidth: 640, minHeight: 520)
        }
        Settings
        {
            PreferencesRootView(coordinator: preferences)
            {
                CoachingSettingsView(coordinator: preferences, readiness: readiness)
            }
            .frame(width: 640, height: 650)
        }
    }
}
