// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4b72b41c-c586-4203-8c8e-e4608fe73cc1
// Created: 2026
// COMPONENT: Device readiness
// PURPOSE: Inspect prerequisites and keep explicitly requested setup separate from capture.
// RELATES: ReadinessCoordinator, ReadinessProvider
// FLOW: Native prerequisite observation -> typed readiness -> explicit setup and refresh.

/// Reports individual prerequisites without claiming that a particular audio route is compatible.
public struct DeviceReadiness: Sendable, Equatable
{
    public let speech: SpeechAssetState
    public let model: ModelReadiness
    public let microphone: CapturePermissionState
    public let meetingAudio: CapturePermissionState
    public let speechLocaleIdentifier: String?

    public init(
        speech: SpeechAssetState = .unchecked,
        model: ModelReadiness = .otherUnavailable,
        microphone: CapturePermissionState = .unknown,
        meetingAudio: CapturePermissionState = .unknown,
        speechLocaleIdentifier: String? = nil
    )
    {
        self.speech = speech
        self.model = model
        self.microphone = microphone
        self.meetingAudio = meetingAudio
        self.speechLocaleIdentifier = speechLocaleIdentifier
    }
}
