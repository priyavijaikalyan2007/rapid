// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f8c51c6e-604e-4db2-99c4-ad30128447bc
// Created: 2026
// COMPONENT: Session error codes
// PURPOSE: Describe controlled failures without arbitrary content-bearing error descriptions.
// RELATES: CoachSessionState, SessionLifecycle
// FLOW: Boundary failure -> stable error code -> recovery message.

import Foundation

/// Contains fixed diagnostic codes and safe recovery text, never underlying framework errors.
public enum SessionError: String, Error, Sendable, LocalizedError
{
    case invalidTransition = "SESSION_INVALID_TRANSITION"
    case captureUnavailable = "SESSION_CAPTURE_UNAVAILABLE"

    /// Explains the failure without exposing meeting content or platform exception text.
    public var errorDescription: String?
    {
        switch self
        {
        case .invalidTransition:
            return "The coaching session cannot change to that state. Stop the session, then try again."
        case .captureUnavailable:
            return "The audio source is unavailable. Check the selected microphone and meeting source, then try again."
        }
    }
}
