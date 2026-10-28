// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: d93e0706-7840-42dc-834d-8b50fa5a19b7
// Created: 2026
// COMPONENT: Native readiness setup
// PURPOSE: Present passive device status and explicitly requested speech setup through native controls.
// RELATES: ReadinessCoordinator, CoachingSettingsView
// FLOW: Settings status -> explicit setup action -> shared readiness updates.

import ComposureCore

#if DEBUG
/// Isolated native-UI fixture. It never invokes Apple asset, permission, model, or capture APIs.
actor UITestReadinessProvider: ReadinessProvider
{
    private var speech: SpeechAssetState = .needsSetup
    private var failsFirstSetup: Bool

    init(failsFirstSetup: Bool)
    {
        self.failsFirstSetup = failsFirstSetup
    }

    func snapshot() -> DeviceReadiness
    {
        DeviceReadiness(
            speech: speech,
            model: .appleIntelligenceNotEnabled,
            microphone: .notRequested,
            meetingAudio: .notApplicable,
            speechLocaleIdentifier: "en-US"
        )
    }

    func setUpSpeech(progress: @escaping @Sendable (Double?) async -> Void) async throws
    {
        await progress(0.5)
        try await Task.sleep(for: .milliseconds(100))
        if failsFirstSetup
        {
            failsFirstSetup = false
            throw ReadinessError.installationFailed
        }
        speech = .ready
        await progress(1)
    }
}
#endif
