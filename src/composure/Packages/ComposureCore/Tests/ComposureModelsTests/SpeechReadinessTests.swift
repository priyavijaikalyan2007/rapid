// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 975c32b2-47b4-46bf-8d9f-3ef136b40a58
// Created: 2026
// COMPONENT: Native readiness boundary tests
// PURPOSE: Verify native state meanings and passive English speech asset inspection.
// RELATES: AppleReadinessService, AppleReadinessMapping
// FLOW: Native statuses -> typed prerequisites -> independent assertions.

import AVFoundation
import ComposureCore
@testable import ComposureModels
import Foundation
import Speech
import Testing

struct SpeechReadinessTests
{
    @Test func everyAssetStateHasADistinctMeaning()
    {
        #expect(AppleReadinessMapping.speech(.installed) == .ready)
        #expect(AppleReadinessMapping.speech(.supported) == .needsSetup)
        #expect(AppleReadinessMapping.speech(.downloading) == .downloading)
        #expect(AppleReadinessMapping.speech(.unsupported) == .unavailable)
    }

    @Test func passiveMicrophoneStatePreservesNotRequested()
    {
        #expect(AppleReadinessMapping.microphone(.notDetermined) == .notRequested)
        #expect(AppleReadinessMapping.microphone(.authorized) == .allowed)
        #expect(AppleReadinessMapping.microphone(.denied) == .denied)
        #expect(AppleReadinessMapping.microphone(.restricted) == .restricted)
    }

    @Test func screenPreflightDoesNotInventADenial()
    {
        #expect(AppleReadinessMapping.meetingAudio(granted: false) == .notGranted)
    }

    @Test func preferredSupportedEnglishLocaleIsSelected()
    {
        let locale = AppleReadinessMapping.englishLocale(
            from: [Locale(identifier: "en-US"), Locale(identifier: "en-IN"), Locale(identifier: "fr-FR")],
            preferred: Locale(identifier: "en-IN")
        )
        #expect(locale?.identifier == "en-IN")
    }

    @Test func englishSelectionDoesNotFallBackToAnotherLanguage()
    {
        #expect(AppleReadinessMapping.englishLocale(
            from: [Locale(identifier: "fr-FR")],
            preferred: Locale(identifier: "fr-FR")
        ) == nil)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["COMPOSURE_EVALUATE_SPEECH"] == "1"))
    func nativeStatusDoesNotReserveOrInstallAssets() async
    {
        let before = await AssetInventory.reservedLocales
        let result = await AppleReadinessService().snapshot()
        let after = await AssetInventory.reservedLocales
        #expect(before == after)
        print("SPEECH_READINESS: state=\(result.speech.rawValue) locale=\(result.speechLocaleIdentifier ?? "none")")
    }
}
