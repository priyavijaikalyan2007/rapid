// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4f537725-882e-4773-a697-75ca0a2ab075
// Created: 2026
// COMPONENT: Debug Mac audio-check controls
// PURPOSE: Provide explicit Start and Stop for a short separate-stream feasibility experiment.
// RELATES: MacCaptureCheck, ReadinessCoordinator
// FLOW: Ready speech assets -> explicit user Start -> native app selection -> counts and Stop.

#if DEBUG
import ComposureCore
import ComposureModels
import SwiftUI

/// A developer-only experiment. Opening this view never starts capture.
@MainActor
struct MacCaptureCheckView: View
{
    private static let shared = MacCaptureCheck(logger: ApplicationDiagnostics.makeLogger())
    @State private var check = Self.shared
    let readiness: ReadinessCoordinator

    var body: some View
    {
        Form
        {
            Section("Development audio check")
            {
                Text(
                    """
                    This developer check provides no coaching feedback. It reports audio delivery and speech-recognition \
                    event counts. It briefly captures separate microphone and meeting-app audio without saving it.
                    """
                )
                Text("Use a test call and harmless test speech. Select the meeting app in Apple's sharing picker.")
                Text(
                    """
                    For Google Meet in Chrome, select Google Chrome in the picker. The selection covers the app \
                    rather than an individual tab.
                    """
                )
                Text("The check requests a stop after 20 seconds. Stop is also available while the check runs.")
            }
            controls
            if readiness.snapshot.speech != .ready || readiness.isSettingUp
            {
                Section("Speech setup")
                {
                    OnDeviceReadinessView(coordinator: readiness)
                }
            }
            Section("Status")
            {
                LabeledContent("Activity", value: check.state.explanation)
                LabeledContent("Speech assets", value: readiness.snapshot.speech.explanation)
                LabeledContent("Prepared analyzers", value: "\(check.preparedAnalyzers) of 2")
                LabeledContent("Microphone buffers", value: "\(check.metrics.microphoneBuffers)")
                LabeledContent("Meeting-audio buffers", value: "\(check.metrics.meetingBuffers)")
                LabeledContent("Microphone recognition events", value: "\(check.metrics.microphoneResults)")
                LabeledContent("Meeting recognition events", value: "\(check.metrics.meetingResults)")
                if check.metrics.hasBothStreams
                {
                    Text("Both streams delivered samples. Confirm that the test call still hears your microphone.")
                }
                if let failure = check.failure
                {
                    Text(failure.explanation).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Audio check")
        .task
        {
            await readiness.refresh()
        }
        .onDisappear
        {
            Task
            {
                await check.stop()
            }
        }
    }

    private var controls: some View
    {
        Section
        {
            HStack
            {
                Button("Start audio check")
                {
                    check.start(localeIdentifier: readiness.snapshot.speechLocaleIdentifier ?? "en-US")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!check.canStart || readiness.snapshot.speech != .ready)
                Button("Stop")
                {
                    Task
                    {
                        await check.stop()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!check.canStop)
            }
            Button("Check speech readiness")
            {
                Task
                {
                    await readiness.refresh()
                }
            }
            .buttonStyle(.bordered)
            .disabled(readiness.isBusy || !check.canStart)
            if readiness.snapshot.speech != .ready
            {
                Text(
                    """
                    Start becomes available when Speech model shows Ready. Use Set up speech or Check device \
                    readiness below.
                    """
                )
                .foregroundStyle(.secondary)
            }
            Text(
                """
                Only sample and recognition-event counts appear here. Recognition text is discarded. No recording \
                or transcript file is created.
                """
            )
            .font(.footnote).foregroundStyle(.secondary)
        }
    }
}
#endif
