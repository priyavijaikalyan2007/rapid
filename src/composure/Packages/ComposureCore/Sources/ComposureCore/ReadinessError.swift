// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 0a9193ef-dff0-429b-8295-6ba9b6b4a738
// Created: 2026
// COMPONENT: Device readiness
// PURPOSE: Inspect prerequisites and keep explicitly requested setup separate from capture.
// RELATES: ReadinessCoordinator, ReadinessProvider
// FLOW: Native prerequisite observation -> typed readiness -> explicit setup and refresh.

/// Fixed categories prevent framework messages from becoming UI or diagnostic content.
public enum ReadinessError: Error, Sendable, Equatable
{
    case unsupported
    case busy
    case installationFailed

    public var explanation: String
    {
        switch self
        {
        case .unsupported: return "Speech setup is unavailable for this device or English locale. Check the device status."
        case .busy: return "Speech setup is already running. Wait for it to finish before trying again."
        case .installationFailed:
            return "Speech setup did not finish. Check your connection and available storage, then try setup again."
        }
    }
}
