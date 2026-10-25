// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 0ef7b6ba-350a-4670-8d63-a6fba1689a41
// Created: 2026
// COMPONENT: macOS navigation shell
// PURPOSE: Provide standard sidebar navigation without business logic in views.
// RELATES: AppSection, FeaturePlaceholder
// FLOW: Sidebar selection -> detail view.

import ComposureCore
import SwiftUI

/// Uses the system sidebar, keyboard navigation, and semantic appearance.
struct MacRootView: View
{
    let coordinator: PreferencesCoordinator
    @State private var selection: AppSection? = .home

    var body: some View
    {
        NavigationSplitView
        {
            List(AppSection.allCases, selection: $selection)
            { section in
                Label(section.rawValue, systemImage: section.symbol)
                    .tag(section)
            }
            .navigationTitle("Composure")
        }
        detail:
        {
            if selection == .settings
            {
                CoachingSettingsView(coordinator: coordinator)
            }
            else
            {
                FeaturePlaceholder(section: selection ?? .home)
            }
        }
    }
}
