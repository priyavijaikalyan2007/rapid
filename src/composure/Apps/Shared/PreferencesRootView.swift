// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 39daa55f-cd17-434c-8ad8-b6bd38a47123
// Created: 2026
// COMPONENT: Preference-aware app root
// PURPOSE: Show first-run setup or explicit recovery before ordinary application navigation.
// RELATES: PreferencesCoordinator, OnboardingView, PreferencesRecoveryView
// FLOW: Accepted preference state -> onboarding, recovery, or app content.

import ComposureCore
import SwiftUI

/// Shares one readiness decision across the main window and the Mac settings window.
struct PreferencesRootView<Content: View>: View
{
    let coordinator: PreferencesCoordinator
    private let content: Content

    init(coordinator: PreferencesCoordinator, @ViewBuilder content: () -> Content)
    {
        self.coordinator = coordinator
        self.content = content()
    }

    var body: some View
    {
        switch coordinator.state
        {
        case .unavailable(let error):
            PreferencesRecoveryView(coordinator: coordinator, error: error)
        case .ready(let preferences):
            if preferences.hasCompletedOnboarding
            {
                content
            }
            else
            {
                OnboardingView(coordinator: coordinator)
            }
        }
    }
}
