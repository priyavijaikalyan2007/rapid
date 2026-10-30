// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9e9deede-6884-4161-b04f-73ef2dbb1e11
// Created: 2026
// COMPONENT: Native coaching settings
// PURPOSE: Edit a retained preference draft, save explicitly, and provide a scoped profile reset.
// RELATES: ProfileFields, PreferencesCoordinator
// FLOW: Native controls -> retained draft -> explicit save or confirmed profile reset.

import ComposureCore
import SwiftUI

/// The shared coordinator retains unsaved choices when the user changes navigation destinations.
struct CoachingSettingsView: View
{
    @Bindable var coordinator: PreferencesCoordinator
    @Bindable var readiness: ReadinessCoordinator
    @State private var confirmsReset = false

    var body: some View
    {
        Form
        {
            Section
            {
                Text("Select Save to keep your changes. Unsaved choices remain while you navigate within the app.")
                    .foregroundStyle(.secondary)
            }
            ProfileFields(profile: $coordinator.draft.profile)
            sessionDefaults
            privacyStatus
            Section
            {
                Button("Reset coaching profile", role: .destructive)
                {
                    confirmsReset = true
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .safeAreaInset(edge: .bottom)
        {
            saveControls
        }
        .alert("Reset coaching profile?", isPresented: $confirmsReset)
        {
            Button("Reset profile", role: .destructive)
            {
                coordinator.resetProfile()
            }
            Button("Cancel", role: .cancel)
            {
            }
        }
        message:
        {
            Text(
                "This resets coaching focus and cue preferences. Setup completion and session defaults stay unchanged."
            )
        }
    }

    private var sessionDefaults: some View
    {
        Section
        {
            Picker("Default conversation style", selection: $coordinator.draft.defaultSessionStyle)
            {
                ForEach(SessionStyle.allCases, id: \.self)
                {
                    Text($0.rawValue).tag($0)
                }
            }
            .help("Choose the initial style for future conversation setup. You can change it for each conversation.")
            LabeledContent("Coaching language", value: coordinator.draft.language.rawValue)
        }
        header: {
            Text("Session defaults")
        }
        footer: {
            Text("English is the only supported coaching language in V1.")
        }
    }

    private var privacyStatus: some View
    {
        Section("Privacy and on-device status")
        {
            LabeledContent("Cloud AI", value: "Not used")
            LabeledContent("Meeting history", value: "Not stored")
            #if os(macOS)
            LabeledContent("Audio capture", value: "Explicit Start in Live Coach")
            #else
            LabeledContent("Audio capture", value: "Not available yet")
            #endif
            LabeledContent("Meeting recording", value: "Disabled by design")
            LabeledContent("Transcript storage", value: "Disabled by design")
            OnDeviceReadinessView(coordinator: readiness)
            Text(
                """
                Only coaching choices and app preferences are saved. Your device's backups can include these \
                preferences.
                """
            )
            .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var hasChanges: Bool
    {
        guard case .ready(let saved) = coordinator.state
        else
        {
            return false
        }
        return saved != coordinator.draft
    }

    private var saveControls: some View
    {
        VStack(alignment: .leading, spacing: 8)
        {
            PreferenceSaveStatusView(coordinator: coordinator)
            ViewThatFits(in: .horizontal)
            {
                HStack
                {
                    saveStatus
                    Spacer()
                    saveActions
                }
                VStack(alignment: .leading, spacing: 8)
                {
                    saveStatus
                    HStack
                    {
                        saveActions
                    }
                }
            }
        }
        .padding()
        .background(.bar)
    }

    private var saveStatus: some View
    {
        Text(hasChanges ? "Unsaved changes" : "Preferences saved").font(.caption)
    }

    @ViewBuilder private var saveActions: some View
    {
        Button("Discard changes")
        {
            coordinator.discardChanges()
        }.disabled(!hasChanges)
        Button("Save")
        {
            coordinator.saveDraft()
        }
        .disabled(!hasChanges && coordinator.saveError == nil)
        .buttonStyle(.borderedProminent)
        .keyboardShortcut("s", modifiers: .command)
    }
}
