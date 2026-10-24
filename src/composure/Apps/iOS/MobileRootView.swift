// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 406e6834-c5c0-4f41-96ab-a3fe7ae16305
// Created: 2026
// COMPONENT: Mobile navigation shell
// PURPOSE: Provide native Prepare, Live Coach, and Settings tabs for iPhone and iPad.
// RELATES: FeaturePlaceholder, AppSection
// FLOW: Tab selection -> navigation stack -> feature status.

import SwiftUI

/// Keeps system tab behavior and Dynamic Type without custom navigation controls.
struct MobileRootView: View
{
    var body: some View
    {
        TabView
        {
            featureTab(.prepare)
            featureTab(.live)
            featureTab(.settings)
        }
    }

    /// Each feature owns a navigation stack so later screens retain standard Back behavior.
    private func featureTab(_ section: AppSection) -> some View
    {
        NavigationStack
        {
            FeaturePlaceholder(section: section)
        }
        .tabItem
        {
            Label(section.rawValue, systemImage: section.symbol)
        }
    }
}
