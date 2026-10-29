// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000033
// Created: 2026
// COMPONENT: Live session coordination
// PURPOSE: Keep capture and coaching bounded, explicit, and transient across native lifecycle changes.
// RELATES: LiveSessionCoordinator, LiveTranscriptionSource, LiveCoachingModel
// FLOW: Explicit Start -> bounded private processing -> sparse cue -> Stop and clear.

/// Owns native resources. No capture, permission request, or picker may occur before explicit start.
@MainActor
public protocol LiveTranscriptionSource: AnyObject
{
    func start(
        localeIdentifier: String,
        receive: @escaping @MainActor @Sendable (TranscriptEvent) -> Void,
        failure: @escaping @MainActor @Sendable (LiveSessionError) -> Void
    ) async throws

    /// Unblocks a pending picker and prevents new resources from starting during cancellation.
    func cancelStart()

    /// Returns true only when native capture is confirmed stopped.
    func stop() async -> Bool
}
