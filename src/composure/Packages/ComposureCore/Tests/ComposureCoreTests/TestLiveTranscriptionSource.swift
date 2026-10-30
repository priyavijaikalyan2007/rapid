// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000021
// Created: 2026
// COMPONENT: Live lifecycle verification
// PURPOSE: Verify session privacy and cancellation with synthetic inputs and controlled services.
// RELATES: LiveSessionCoordinator, LiveTranscriptionSource, LiveCoachingModel
// FLOW: Explicit synthetic session -> events or errors -> deterministic cleanup assertions.

import ComposureCore

@MainActor
final class TestLiveTranscriptionSource: LiveTranscriptionSource
{
    var startCount = 0
    var stopCount = 0
    var confirmsStop = true
    var cancelsSelection = false
    var startFailure: LiveSessionError?
    var receive: (@MainActor @Sendable (TranscriptEvent) -> Void)?
    var reportFailure: (@MainActor @Sendable (LiveSessionError) -> Void)?

    func start(
        localeIdentifier: String,
        receive: @escaping @MainActor @Sendable (TranscriptEvent) -> Void,
        failure: @escaping @MainActor @Sendable (LiveSessionError) -> Void
    ) async throws
    {
        startCount += 1
        self.receive = receive
        reportFailure = failure
        if cancelsSelection
        {
            throw CancellationError()
        }
        if let startFailure
        {
            throw startFailure
        }
    }

    func cancelStart()
    {
    }

    func stop() async -> Bool
    {
        stopCount += 1
        return confirmsStop
    }
}
