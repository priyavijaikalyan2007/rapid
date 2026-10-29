// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 938db25a-fd6f-44b8-bff6-87b98d6c338c
// Created: 2026
// COMPONENT: Early capture experiment
// PURPOSE: Keep the developer check bounded and require distinct microphone and meeting streams.
// RELATES: MacCaptureCheck, CaptureCheckMetrics
// FLOW: Separate sample metadata -> bounded validation -> explicit activity or failure.

/// Describes experiment activity without treating sample delivery as microphone-sharing proof.
public enum CaptureCheckState: Sendable
{
    case idle
    case requestingPermission
    case selecting
    case preparing
    case running
    case stopping
    case completed
    case failed

    public var explanation: String
    {
        switch self
        {
        case .idle: return "Not listening"
        case .requestingPermission: return "Waiting for microphone permission"
        case .selecting: return "Choose a test app"
        case .preparing: return "Preparing two speech analyzers"
        case .running: return "Listening for the development check"
        case .stopping: return "Stopping capture"
        case .completed: return "Audio check ended"
        case .failed: return "Audio check needs attention"
        }
    }
}
