// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000003
// Created: 2026
// COMPONENT: Transient live coaching
// PURPOSE: Bound private speech context and validate sparse actionable cues.
// RELATES: LiveSessionCoordinator, CueArbiter, ConversationBuffer
// FLOW: Explicit listening -> bounded context -> validated temporary cue -> Stop and clear.

import Foundation

/// Only fixed messages cross native and model error boundaries.
public enum LiveSessionError: String, Error, LocalizedError, Sendable
{
    case invalidSpeech
    case invalidCue
    case objectiveTooLong
    case speechUnavailable
    case captureFailed
    case stopUnconfirmed
    case modelUnavailable
    case microphoneDenied
    case microphoneUnavailable
    case meetingAudioUnavailable
    case routeChanged
    case sourceChanged

    public var errorDescription: String?
    {
        switch self
        {
        case .invalidSpeech: return "Speech timing or text could not be processed. Stop and start a new session."
        case .microphoneDenied: return "Microphone access is unavailable. Allow Composure in System Settings, then start again."
        case .microphoneUnavailable: return """
            The separate microphone stream is unavailable. Check the microphone, then retry. Both audio streams are \
            required.
            """
        case .meetingAudioUnavailable: return "Meeting audio is unavailable. Confirm that the selected application plays speech, then start again."
        case .routeChanged: return "The audio route or system session changed. Confirm your audio setup before starting again."
        case .sourceChanged: return "The selected application changed. Select the application again before starting."
        case .modelUnavailable: return "On-device coaching is unavailable. Check Apple Intelligence and model readiness, then retry."
        case .invalidCue: return "A coaching suggestion did not pass validation."
        case .objectiveTooLong: return "Use at most 512 bytes for the meeting objective."
        case .speechUnavailable: return "On-device speech is unavailable. Check speech setup before starting again."
        case .captureFailed: return "Audio capture stopped. Check the microphone and selected application, then start again."
        case .stopUnconfirmed: return "Audio capture could not confirm Stop. Retry Stop, or quit Composure."
        }
    }
}
