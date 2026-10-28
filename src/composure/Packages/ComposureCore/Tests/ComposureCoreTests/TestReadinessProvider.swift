// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 6dd595d0-76d1-4567-9a04-9eaaedcbd8bb
// Created: 2026
// COMPONENT: Device readiness
// PURPOSE: Inspect prerequisites and keep explicitly requested setup separate from capture.
// RELATES: ReadinessCoordinator, ReadinessProvider
// FLOW: Native prerequisite observation -> typed readiness -> explicit setup and refresh.

import ComposureCore
import Foundation

/// Controlled setup either completes immediately or waits for test cancellation. It has no native effects.
actor TestReadinessProvider: ReadinessProvider
{
    private let afterSetup: SpeechAssetState?
    private let shouldFail: Bool
    private var speech: SpeechAssetState = .needsSetup
    private var handler: (@Sendable (Double?) async -> Void)?
    private(set) var setupCount = 0

    init(afterSetup: SpeechAssetState? = nil, shouldFail: Bool = false)
    {
        self.afterSetup = afterSetup
        self.shouldFail = shouldFail
    }

    func snapshot() -> DeviceReadiness
    {
        DeviceReadiness(speech: speech)
    }

    func setSpeech(_ value: SpeechAssetState)
    {
        speech = value
    }

    func setUpSpeech(progress: @escaping @Sendable (Double?) async -> Void) async throws
    {
        setupCount += 1
        handler = progress
        if shouldFail
        {
            throw ReadinessError.installationFailed
        }
        if let afterSetup
        {
            speech = afterSetup
            await progress(1)
            return
        }
        try await Task.sleep(for: .seconds(60))
    }

    func waitForProgressHandler() async
    {
        while handler == nil
        {
            await Task.yield()
        }
    }

    func sendProgress(_ value: Double?) async
    {
        await handler?(value)
    }
}
