// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 84fc3ec4-9c4e-48af-ae41-6e81e0e3a0fb
// Created: 2026
// COMPONENT: Native conversation preparation
// PURPOSE: Connect saved profile choices to explicit generation, cancellation, editing, and clearing.
// RELATES: PreparationCoordinator, PreparationService
// FLOW: Native controls -> bounded transient preparation -> explicit clear or lifecycle cleanup.

import ComposureCore
import SwiftUI

/// The root owns the coordinator so tab changes retain input. Leaving the screen cancels active work.
struct PrepareView: View
{
    @Bindable var coordinator: PreparationCoordinator
    let preferences: PreferencesCoordinator
    let service: PreparationService
    @FocusState private var focusedField: String?
    @State private var initializedDefaults = false

    var body: some View
    {
        Form
        {
            if let result = coordinator.result
            {
                PreparationResultView(result: result)
            }
            else
            {
                Section("On-device status")
                {
                    ModelReadinessView(service: service)
                }
                PreparationFields(coordinator: coordinator, focus: $focusedField)
                    .disabled(coordinator.isPreparing)
                if let error = coordinator.error
                {
                    Section
                    {
                        Text(error.errorDescription ?? "Preparation could not finish. Try again.")
                    }
                }
            }
            privacyDisclosure
        }
        .formStyle(.grouped)
        .navigationTitle("Prepare")
        .privacySensitive()
        .safeAreaInset(edge: .bottom)
        {
            actions
        }
        .onAppear
        {
            applyDefaultsOnce()
        }
        .onDisappear
        {
            coordinator.cancel()
        }
    }

    private var privacyDisclosure: some View
    {
        Section
        {
            Text("Preparation stays in memory and is not restored after relaunch. No audio is captured.")
            #if os(iOS)
            Text("Preparation clears when Composure becomes inactive, including when you switch apps.")
            #else
            Text("Select Clear when you finish preparing.")
            #endif
        }.font(.footnote).foregroundStyle(.secondary)
    }

    private var actions: some View
    {
        HStack(spacing: 16)
        {
            Button("Clear")
            { focusedField = nil
                coordinator.clear()
            }
            .accessibilityIdentifier("prepare.clear")
            Spacer()
            if coordinator.isPreparing
            {
                ProgressView().accessibilityLabel("Preparing conversation")
                Button("Cancel")
                {
                    coordinator.cancel()
                }.accessibilityIdentifier("prepare.cancel")
            }
            else if coordinator.result != nil
            {
                Button("Edit inputs")
                {
                    coordinator.cancel()
                }.accessibilityIdentifier("prepare.edit")
            }
            else
            {
                Button("Prepare conversation")
                {
                    generate()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("prepare.generate")
                .keyboardShortcut(.defaultAction)
            }
        }.padding().background(.bar)
    }

    private func generate()
    {
        focusedField = nil
        guard case .ready(let saved) = preferences.state
        else
        {
            return
        }
        Task
        {
            await coordinator.prepare(profile: saved.profile)
        }
    }

    private func applyDefaultsOnce()
    {
        guard !initializedDefaults, case .ready(let saved) = preferences.state
        else
        {
            return
        }
        coordinator.highStakes = saved.defaultSessionStyle == .highStakes
        initializedDefaults = true
    }
}
