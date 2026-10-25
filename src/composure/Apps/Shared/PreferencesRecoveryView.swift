// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: e04bcc6a-e12b-498d-b822-0c33c3dc6207
// Created: 2026
// COMPONENT: Preference load recovery
// PURPOSE: Preserve unreadable preferences until the user retries or explicitly resets the owned record.
// RELATES: PreferencesCoordinator, PreferencesError
// FLOW: Unavailable state -> fixed explanation -> retry or confirmed reset.

import ComposureCore
import SwiftUI

/// Recovery never starts capture and never silently replaces an unreadable record with defaults.
struct PreferencesRecoveryView: View
{
    let coordinator: PreferencesCoordinator
    let error: PreferencesError
    @State private var confirmsReset = false

    var body: some View
    {
        VStack(alignment: .leading, spacing: 20)
        {
            Label("Preferences need attention", systemImage: "exclamationmark.circle").font(.title2)
            Text(error.errorDescription ?? "Saved preferences could not be read.")
            Text("Your saved preferences remain unchanged.").foregroundStyle(.secondary)
            Button("Retry")
            {
                coordinator.reload()
            }.buttonStyle(.borderedProminent)
            Button("Reset saved preferences", role: .destructive)
            {
                confirmsReset = true
            }
        }
        .padding()
        .frame(maxWidth: 560)
        .alert("Reset saved preferences?", isPresented: $confirmsReset)
        {
            Button("Reset saved preferences", role: .destructive)
            {
                coordinator.resetAllPreferences()
            }
            Button("Cancel", role: .cancel)
            {
            }
        }
        message:
        {
            Text("This removes your saved coaching choices and starts setup again.")
        }
    }
}
