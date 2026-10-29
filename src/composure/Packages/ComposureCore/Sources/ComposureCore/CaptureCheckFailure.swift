// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 0ae80120-04ef-4f19-8a1b-b3d574771b1c
// Created: 2026
// COMPONENT: Early capture experiment
// PURPOSE: Keep the developer check bounded and require distinct microphone and meeting streams.
// RELATES: MacCaptureCheck, CaptureCheckMetrics
// FLOW: Separate sample metadata -> bounded validation -> explicit activity or failure.

/// Fixed messages never contain app identities, audio, transcripts, or framework error descriptions.
public enum CaptureCheckFailure: Error, Sendable, Equatable
{
    case speechNotReady
    case microphoneDenied
    case microphoneUnavailable
    case meetingAudioUnavailable
    case analyzerUnavailable
    case unsupportedFormat
    case routeChanged
    case sourceChanged
    case invalidTiming
    case bufferLimit
    case captureFailed
    case stopFailed

    public var explanation: String
    {
        switch self
        {
        case .speechNotReady: return "Set up English speech in Settings, then start this audio check."
        case .microphoneDenied: return "Microphone access is unavailable. Allow Composure in System Settings, then start the check again."
        case .microphoneUnavailable: return """
            The separate microphone stream did not arrive. Check the microphone and retry. Meeting-audio-only coaching \
            is not available.
            """
        case .meetingAudioUnavailable: return "No meeting-audio samples arrived. Play test speech in the selected app, then start the check again."
        case .analyzerUnavailable: return "The device could not prepare two speech analyzers. Close other speech tasks and retry the check."
        case .unsupportedFormat: return "This audio format is unsupported by the check. Select another microphone or audio route and retry."
        case .routeChanged: return "The audio route changed, so the check stopped. Confirm the new route before you start again."
        case .sourceChanged: return "The selected app changed, so the check stopped. Select the app again before you start."
        case .invalidTiming: return "The audio timestamps could not be aligned. The check stopped. Restart after confirming the audio route."
        case .bufferLimit: return """
            Audio processing could not keep pace within its limits. The check stopped. Close other audio tasks and \
            retry.
            """
        case .captureFailed: return "The audio check could not continue. Confirm the selected app and capture permissions, then retry."
        case .stopFailed: return "Capture did not confirm that it stopped. Retry Stop or quit Composure to release audio capture."
        }
    }
}
