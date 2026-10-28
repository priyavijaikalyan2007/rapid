// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 7c66c0a3-87ba-4698-b817-58825d3570af
// Created: 2026
// COMPONENT: Native device readiness
// PURPOSE: Inspect native prerequisites and install speech assets only through explicit setup.
// RELATES: ReadinessProvider, ReadinessCoordinator
// FLOW: Apple status APIs -> typed readiness -> explicitly requested system asset installation.

import AVFoundation
import ComposureCore
import Foundation
import Speech

/// Pure mappings preserve unknown and ungranted states without treating them as authorization.
enum AppleReadinessMapping
{
    static func speech(_ status: AssetInventory.Status) -> SpeechAssetState
    {
        switch status
        {
        case .installed: return .ready
        case .supported: return .needsSetup
        case .downloading: return .downloading
        case .unsupported: return .unavailable
        @unknown default: return .unknown
        }
    }

    static func microphone(_ status: AVAuthorizationStatus) -> CapturePermissionState
    {
        switch status
        {
        case .notDetermined: return .notRequested
        case .authorized: return .allowed
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .unknown
        }
    }

    static func meetingAudio(granted: Bool) -> CapturePermissionState
    {
        granted ? .allowed : .notGranted
    }

    static func englishLocale(from supported: [Locale], preferred: Locale) -> Locale?
    {
        let english = supported.filter
        {
            $0.language.languageCode?.identifier == "en"
        }
        let normalize: (Locale) -> String = {
            $0.identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        }
        return english.first
        {
            normalize($0) == normalize(preferred)
        } ??
        english.first
        {
            normalize($0) == "en-us"
        } ??
        english.sorted
        {
            $0.identifier < $1.identifier
        }.first
    }
}
