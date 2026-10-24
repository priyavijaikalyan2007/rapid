// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c5b9b1d8-d8b5-4454-baa8-800d8c2b60a1
// Created: 2026
// COMPONENT: Session lifecycle policy
// PURPOSE: Require readiness, explicit startup, and cleanup before reuse.
// RELATES: CoachSessionState, SessionError
// FLOW: Requested state -> transition validation -> accepted state.

/// Pure transition policy. The future session coordinator must stop resources before reporting idle.
public struct SessionLifecycle: Sendable
{
    /// The last accepted state. Failed transitions preserve this value.
    public private(set) var state: CoachSessionState = .idle

    /// Creates an idle lifecycle without allocating audio or model resources.
    public init()
    {
    }

    // @entrypoint
    /// Accepts a valid lifecycle step or throws `invalidTransition` without changing state.
    public mutating func transition(to next: CoachSessionState) throws
    {
        guard next == state || allows(next)
        else
        {
            throw SessionError.invalidTransition
        }
        state = next
    }

    /// Keeps cleanup mandatory even when startup or active capture fails.
    private func allows(_ next: CoachSessionState) -> Bool
    {
        switch (state, next)
        {
        case (.idle, .checkingReadiness),
             (.checkingReadiness, .requestingPermissions),
             (.requestingPermissions, .selectingAudioSource),
             (.requestingPermissions, .starting),
             (.selectingAudioSource, .starting),
             (.starting, .listening),
             (.stopping, .idle):
            return true
        case (.checkingReadiness, .stopping), (.requestingPermissions, .stopping),
             (.selectingAudioSource, .stopping), (.starting, .stopping),
             (.listening, .stopping), (.failed, .stopping):
            return true
        case (.checkingReadiness, .failed), (.requestingPermissions, .failed),
             (.selectingAudioSource, .failed), (.starting, .failed), (.listening, .failed):
            return true
        default:
            return false
        }
    }
}
