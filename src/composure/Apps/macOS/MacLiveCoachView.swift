// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000108
// Created: 2026
// COMPONENT: Native Mac live coaching
// PURPOSE: Present explicit listening controls and one brief cue without transcript display or persistence.
// RELATES: MacLiveCoachComposition, LiveSessionCoordinator, MacCuePanel
// FLOW: Explicit Start -> selected audio -> private coaching -> floating cue -> Stop and clear.

import ComposureCore
import SwiftUI

/// An explicit application-selection flow. Merely opening the screen only refreshes passive readiness.
struct MacLiveCoachView: View
{
    @Bindable var session: LiveSessionCoordinator
    let preferences: PreferencesCoordinator
    let readiness: ReadinessCoordinator
    @State private var style: SessionStyle = .normal
    @State private var ownedSessionID: UUID?

    var body: some View
    {
        Form
        {
            Section("Live coaching")
            {
                LabeledContent("Status", value: session.state.rawValue)
                    .accessibilityIdentifier("live.status")
                Text(
                    """
                    Composure processes speech on this Mac. Composure does not save audio, transcript text, or \
                    meeting history.
                    """
                )
                Text("Cues appear only when an action could help. Ordinary discussion can remain silent.")
            }
            setup
            controls
            if let cue = session.cue
            {
                Section("Current cue")
                {
                    Text(verbatim: cue.kind.headline).font(.headline)
                    Text(verbatim: cue.instruction)
                }
            }
            if session.state == .listening && !session.isCoachingAvailable
            {
                Text("Coaching is temporarily unavailable. Listening continues. Stop remains available.")
            }
            Section("On-device readiness")
            {
                OnDeviceReadinessView(coordinator: readiness)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Live Coach")
        .task
        {
            style = acceptedPreferences.defaultSessionStyle
            await readiness.refresh()
        }
        .onDisappear
        {
            if session.canStart
            {
                session.objective = ""
            }
            if let ownedSessionID, ownedSessionID == session.activeSessionID
            {
                Task
                {
                    await session.stop()
                }
            }
        }
    }

    private var setup: some View
    {
        Section
        {
            TextField("Meeting objective (optional)", text: $session.objective)
                .accessibilityIdentifier("live.objective")
                .autocorrectionDisabled()
                .writingToolsBehavior(.disabled)
                .help("State your aim in at most 512 UTF-8 bytes. The objective is cleared when the session ends.")
            Picker("Conversation style", selection: $style)
            {
                ForEach(SessionStyle.allCases, id: \.self)
                {
                    Text($0.rawValue).tag($0)
                }
            }
            Text(
                """
                Select Google Chrome in the sharing picker for Meet. The selection covers the application, \
                including its other tabs.
                """
            )
            Text(
                """
                Use headphones to reduce echo. Interruption and speaking-time cues are unavailable until speaker \
                separation is verified.
                """
            )
            .font(.callout).foregroundStyle(.secondary)
        }
        header: {
            Text("This meeting")
        }
        footer: {
            Text("Saved Coaching Profile choices guide the cues. The objective is used only during this session.")
        }
        .disabled(!session.canStart)
    }

    private var controls: some View
    {
        Section
        {
            if let error = session.error
            {
                Text(verbatim: error.errorDescription ?? "The session stopped.")
                    .accessibilityIdentifier("live.error")
            }
            HStack
            {
                Button("Start coaching")
                {
                    session.start(
                        localeIdentifier: readiness.snapshot.speechLocaleIdentifier ?? "en-US",
                        profile: acceptedPreferences.profile,
                        style: style
                    )
                    ownedSessionID = session.activeSessionID
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("live.start")
                .disabled(!session.canStart || readiness.snapshot.speech != .ready ||
                    readiness.snapshot.model != .available)
                Button("Stop")
                {
                    Task
                    {
                        await session.stop()
                    }
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("live.stop")
                .disabled(!session.canStop || session.state == .stopping)
            }
            if session.canStart && (readiness.snapshot.speech != .ready || readiness.snapshot.model != .available)
            {
                Text("Start needs ready English speech assets and an available on-device model. Check readiness below.")
            }
            if session.state == .starting || session.state == .stopping
            {
                ProgressView()
            }
        }
    }

    private var acceptedPreferences: AppPreferences
    {
        guard case .ready(let saved) = preferences.state
        else
        {
            return AppPreferences()
        }
        return saved
    }
}
