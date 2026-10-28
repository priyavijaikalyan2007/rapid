// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 3b9b6ed7-51ee-48e2-8f24-03574db09b53
// Created: 2026
// COMPONENT: Native readiness setup
// PURPOSE: Present passive device status and explicitly requested speech setup through native controls.
// RELATES: ReadinessCoordinator, CoachingSettingsView
// FLOW: Settings status -> explicit setup action -> shared readiness updates.

import ComposureCore
import SwiftUI

/// Displays prerequisite status without requesting capture or starting a live session.
struct OnDeviceReadinessView: View
{
    @Bindable var coordinator: ReadinessCoordinator

    var body: some View
    {
        VStack(alignment: .leading, spacing: 12)
        {
            LabeledContent("Speech model", value: coordinator.snapshot.speech.explanation)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Speech model")
                .accessibilityValue(coordinator.snapshot.speech.explanation)
                .accessibilityIdentifier("readiness.speech")
            if let locale = coordinator.snapshot.speechLocaleIdentifier
            {
                LabeledContent(
                    "Speech language",
                    value: Locale.current.localizedString(forIdentifier: locale) ?? locale
                )
            }
            Text(coordinator.snapshot.model.explanation)
            LabeledContent("Microphone permission", value: coordinator.snapshot.microphone.explanation)
            LabeledContent("Meeting-audio permission", value: coordinator.snapshot.meetingAudio.explanation)
            actions
            Text("Checking status and setting up speech do not start audio capture.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .task
        {
            await coordinator.refresh()
        }
    }

    private var actions: some View
    {
        VStack(alignment: .leading, spacing: 8)
        {
            if let error = coordinator.error
            {
                Text(error.explanation).foregroundStyle(.secondary)
                    .accessibilityIdentifier("readiness.error")
            }
            Button("Check device readiness")
            {
                Task
                {
                    await coordinator.refresh()
                }
            }
            .buttonStyle(.bordered)
            .disabled(coordinator.isBusy)
            .accessibilityIdentifier("readiness.refresh")
            if coordinator.snapshot.speech.canSetUp || coordinator.isSettingUp
            {
                setupControls
            }
        }
    }

    private var setupControls: some View
    {
        VStack(alignment: .leading, spacing: 8)
        {
            Button("Set up speech")
            {
                Task
                {
                    await coordinator.setUpSpeech()
                }
            }
            .buttonStyle(.bordered)
            .disabled(coordinator.isBusy)
            .accessibilityIdentifier("readiness.setup")
            if coordinator.isSettingUp
            {
                ProgressView("Setting up speech…", value: coordinator.progress)
                    .accessibilityIdentifier("readiness.progress")
            }
            Text("Apple downloads and manages the speech assets. Downloads may resume later if a connection fails.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}
