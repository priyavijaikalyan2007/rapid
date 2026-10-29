// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000034
// Created: 2026
// COMPONENT: Live session coordination
// PURPOSE: Keep capture and coaching bounded, explicit, and transient across native lifecycle changes.
// RELATES: LiveSessionCoordinator, LiveTranscriptionSource, LiveCoachingModel
// FLOW: Explicit Start -> bounded private processing -> sparse cue -> Stop and clear.

/// A failed unconfirmed Stop remains active for cleanup purposes and blocks a new session.
public enum LiveSessionState: String, Sendable
{
    case idle = "Not listening"
    case starting = "Starting"
    case listening = "Listening"
    case stopping = "Stopping"
    case failed = "Stopped"
}
