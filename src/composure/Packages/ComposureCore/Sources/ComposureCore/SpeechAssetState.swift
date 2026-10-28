// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 3ffd4a28-df05-4cf7-9a4d-8edee57baa3e
// Created: 2026
// COMPONENT: Device readiness
// PURPOSE: Inspect prerequisites and keep explicitly requested setup separate from capture.
// RELATES: ReadinessCoordinator, ReadinessProvider
// FLOW: Native prerequisite observation -> typed readiness -> explicit setup and refresh.

/// Device speech prerequisites. Ready means that the configured module's assets are installed.
public enum SpeechAssetState: String, Sendable, Equatable, CaseIterable
{
    case unchecked
    case unavailable
    case unsupportedLocale
    case needsSetup
    case downloading
    case ready
    case unknown

    public var canSetUp: Bool
    {
        self == .needsSetup || self == .downloading
    }

    public var explanation: String
    {
        switch self
        {
        case .unchecked: return "Not checked"
        case .unavailable: return "On-device speech is unavailable on this device"
        case .unsupportedLocale: return "English speech is not supported on this device"
        case .needsSetup: return "Needs setup"
        case .downloading: return "Downloading or waiting for download"
        case .ready: return "Ready"
        case .unknown: return "Unable to determine speech status"
        }
    }
}
