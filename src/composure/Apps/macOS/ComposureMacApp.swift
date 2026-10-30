// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 3786022e-f9bb-4eaa-93f7-83343ae6db93
// Created: 2026
// COMPONENT: macOS application entry point
// PURPOSE: Own native preferences, readiness, and one explicitly started live coach.
// RELATES: MacRootView, ApplicationDiagnostics
// FLOW: Application launch -> native controls -> explicit transient coaching session.

import ComposureCore
import SwiftUI

/// Opening a window is passive. Capture requires a separate explicit Start action.
@main
struct ComposureMacApp: App
{
    @State private var preferences = AppPreferencesComposition.makeCoordinator()
    @State private var services = MacLiveCoachComposition()
    @State private var readiness = ReadinessComposition.makeCoordinator()
    @NSApplicationDelegateAdaptor(ComposureMacDelegate.self) private var appDelegate
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
                MacRootView(
                    coordinator: preferences,
                    preparationService: services.preparation,
                    readiness: readiness,
                    live: services.session
                )
            }
            .frame(minWidth: 640, minHeight: 520)
            .onAppear
            {
                appDelegate.session = services.session
            }
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
