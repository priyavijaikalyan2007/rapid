// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 5eac5e44-e70b-4f2c-806f-be4debb0323c
// Created: 2026
// COMPONENT: Device readiness
// PURPOSE: Inspect prerequisites and keep explicitly requested setup separate from capture.
// RELATES: ReadinessCoordinator, ReadinessProvider
// FLOW: Native prerequisite observation -> typed readiness -> explicit setup and refresh.

/// A passive observation. Not granted does not imply that a permission request was denied.
public enum CapturePermissionState: String, Sendable, Equatable
{
    case unknown
    case notRequested
    case allowed
    case denied
    case restricted
    case notGranted
    case notApplicable

    public var explanation: String
    {
        switch self
        {
        case .unknown: return "Not checked"
        case .notRequested: return "Not requested"
        case .allowed: return "Allowed"
        case .denied: return "Denied in system settings"
        case .restricted: return "Restricted by device policy"
        case .notGranted: return "Not granted"
        case .notApplicable: return "Not available on this platform"
        }
    }
}
