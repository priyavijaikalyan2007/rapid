// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000101
// Created: 2026
// COMPONENT: Native Mac live coaching
// PURPOSE: Present explicit listening controls and one brief cue without transcript display or persistence.
// RELATES: MacLiveCoachComposition, LiveSessionCoordinator, MacCuePanel
// FLOW: Explicit Start -> selected audio -> private coaching -> floating cue -> Stop and clear.

#if DEBUG
import ComposureCore
import ComposureModels

/// Synthetic fixture selected only with both isolated-preference and live-UI-test launch arguments.
@MainActor
final class UITestLiveSource: LiveTranscriptionSource
{
    private var delivery: Task<Void, Never>?

    func start(
        localeIdentifier: String, receive: @escaping @MainActor @Sendable (TranscriptEvent) -> Void,
        failure: @escaping @MainActor @Sendable (LiveSessionError) -> Void
    ) async throws
    {
        delivery = Task
        {
            do
            {
                try await Task.sleep(for: .milliseconds(200))
                let now = MacMeetingAudioSource.now()
                let event = try TranscriptEvent(
                    channel: .meeting,
                    startSeconds: now - 2,
                    endSeconds: now - 0.1,
                    text: "Which promotion criteria remain unmet?",
                    isFinal: true
                )
                receive(event)
            }
            catch
            {
            }
        }
    }

    func cancelStart()
    {
        delivery?.cancel()
    }

    func stop() async -> Bool
    {
        cancelStart()
        await delivery?.value
        delivery = nil
        return true
    }
}
#endif
