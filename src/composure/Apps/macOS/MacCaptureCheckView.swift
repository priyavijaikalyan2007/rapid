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
                    Live coaching is not available yet. This check briefly captures separate microphone and \
                    meeting-app audio without saving it.
                    """
                )
                Text("Use a test call and harmless test speech. Select the meeting app in Apple's sharing picker.")
                Text("The check requests a stop after 20 seconds. Stop is also available while the check runs.")
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
            controls
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
            if readiness.snapshot.speech != .ready
            {
                Text("Set up speech in Settings before starting this check.").foregroundStyle(.secondary)
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
