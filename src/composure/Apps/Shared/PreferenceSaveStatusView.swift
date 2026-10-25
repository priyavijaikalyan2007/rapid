// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 781014aa-d82a-46bb-aeb7-786ae242b506
// Created: 2026
// COMPONENT: Preference save feedback
// PURPOSE: Keep save failures visible while the user's draft remains intact.
// RELATES: PreferencesCoordinator
// FLOW: Controlled save error -> readable message -> retry or explicit reload.

import ComposureCore
import SwiftUI

/// Displays only fixed application errors, never a raw storage exception or preference payload.
struct PreferenceSaveStatusView: View
{
    let coordinator: PreferencesCoordinator

    var body: some View
    {
        if let error = coordinator.saveError
        {
            VStack(alignment: .leading, spacing: 8)
            {
                Text(error.errorDescription ?? "Preferences could not be saved.")
                    .font(.callout)
                    .accessibilityIdentifier("preferences.saveError")
                if error != .saveFailed
                {
                    Button("Reload saved preferences")
                    {
                        coordinator.reload()
                    }
                }
            }
            .accessibilityElement(children: .contain)
        }
    }
}
