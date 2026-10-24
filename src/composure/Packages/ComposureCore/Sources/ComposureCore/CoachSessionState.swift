// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 263ae9b6-be22-4d99-a218-0c0aca848620
// Created: 2026
// COMPONENT: Coach session states
// PURPOSE: Express one lifecycle state without unrelated status flags.
// RELATES: SessionLifecycle, SessionError
// FLOW: Session coordinator -> transition policy -> observable UI state.

/// Identifies a lifecycle phase. State alone does not start or own capture resources.
public enum CoachSessionState: Sendable, Equatable
{
    case idle
    case checkingReadiness
    case requestingPermissions
    case selectingAudioSource
    case starting
    case listening
    case stopping
    case failed(SessionError)
}
