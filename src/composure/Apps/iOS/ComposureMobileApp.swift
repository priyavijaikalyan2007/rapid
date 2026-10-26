// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 179983c4-d4f8-4f91-9793-d03884391668
// Created: 2026
// COMPONENT: iPhone and iPad application entry point
// PURPOSE: Launch the shared mobile shell without audio permissions or background work.
// RELATES: MobileRootView, ApplicationDiagnostics
// FLOW: Application launch -> local launch event -> native mobile navigation.

import ComposureCore
import SwiftUI

/// Supports iPhone and iPad through the same mobile application target.
@main
struct ComposureMobileApp: App
{
    @State private var preferences = AppPreferencesComposition.makeCoordinator()
    @State private var preparationService = PreparationComposition.makeService()
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
                MobileRootView(coordinator: preferences, preparationService: preparationService)
            }
        }
    }
}
