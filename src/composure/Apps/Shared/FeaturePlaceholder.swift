// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 8ea8818b-781c-4708-9775-f461d4cd6e18
// Created: 2026
// COMPONENT: Foundation feature surface
// PURPOSE: Present an honest native empty state before feature implementation.
// RELATES: AppSection, MacRootView, MobileRootView
// FLOW: Navigation selection -> native unavailable view -> feature status.

import SwiftUI

/// Contains no inputs, persistence, permissions, capture, or model requests.
struct FeaturePlaceholder: View
{
    let section: AppSection

    var body: some View
    {
        ContentUnavailableView(
            section.rawValue,
            systemImage: section.symbol,
            description: Text(section.detail)
        )
        .navigationTitle(section.rawValue)
    }
}
