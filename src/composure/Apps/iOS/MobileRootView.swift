// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 406e6834-c5c0-4f41-96ab-a3fe7ae16305
// Created: 2026
// COMPONENT: Mobile navigation shell
// PURPOSE: Provide native Prepare, Live Coach, and Settings tabs for iPhone and iPad.
// RELATES: FeaturePlaceholder, AppSection
// FLOW: Tab selection -> navigation stack -> feature status.

import ComposureCore
import SwiftUI

/// Keeps system tab behavior and Dynamic Type without custom navigation controls.
struct MobileRootView: View
{
    let coordinator: PreferencesCoordinator
    let preparationService: PreparationService
    @State private var preparation: PreparationCoordinator
    @Environment(\.scenePhase) private var scenePhase

    init(coordinator: PreferencesCoordinator, preparationService: PreparationService)
    {
        self.coordinator = coordinator
        self.preparationService = preparationService
        _preparation = State(initialValue: PreparationComposition.makeCoordinator(service: preparationService))
    }

    var body: some View
    {
        TabView
        {
            featureTab(.prepare)
            featureTab(.live)
            featureTab(.settings)
        }
        .opacity(scenePhase == .active ? 1 : 0)
        .accessibilityHidden(scenePhase != .active)
        .background(PreparationPrivacyShield
        {
            preparation.clear()
        })
        .onChange(of: scenePhase)
        {
            if scenePhase != .active
            {
                preparation.clear()
            }
        }
    }

    /// Each feature owns a navigation stack so later screens retain standard Back behavior.
    private func featureTab(_ section: AppSection) -> some View
    {
        NavigationStack
        {
            if section == .settings
            {
                CoachingSettingsView(coordinator: coordinator, preparationService: preparationService)
            }
            else if section == .prepare
            {
                PrepareView(coordinator: preparation, preferences: coordinator, service: preparationService)
            }
            else
            {
                FeaturePlaceholder(section: section)
            }
        }
        .tabItem
        {
            Label(section.rawValue, systemImage: section.symbol)
        }
    }
}
