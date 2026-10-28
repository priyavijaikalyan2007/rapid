// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 78bda497-6620-4c41-ace7-b5d5424130f9
// Created: 2026
// COMPONENT: Device readiness contracts
// PURPOSE: Verify passive checks and explicit serialized speech setup without native effects.
// RELATES: ReadinessCoordinator, ReadinessProvider
// FLOW: Controlled provider -> readiness actions -> independent state assertions.

import Foundation
import Testing
@testable import ComposureCore

@MainActor
struct ReadinessCoordinatorTests
{
    @Test func passiveRefreshNeverRequestsSetup() async
    {
        let provider = TestReadinessProvider()
        let coordinator = ReadinessCoordinator(provider: provider)
        await coordinator.refresh()
        #expect(await provider.setupCount == 0)
        #expect(coordinator.snapshot.speech == .needsSetup)
    }

    @Test func explicitSetupRefreshesInstalledStatus() async
    {
        let provider = TestReadinessProvider(afterSetup: .ready)
        let coordinator = ReadinessCoordinator(provider: provider)
        await coordinator.setUpSpeech()
        #expect(coordinator.snapshot.speech == .ready)
        #expect(await provider.setupCount == 1)
    }

    @Test func successfulRequestDoesNotImplyReady() async
    {
        let provider = TestReadinessProvider(afterSetup: .downloading)
        let coordinator = ReadinessCoordinator(provider: provider)
        await coordinator.setUpSpeech()
        #expect(coordinator.snapshot.speech == .downloading)
    }

    @Test func setupFailureRemainsRetryable() async
    {
        let provider = TestReadinessProvider(shouldFail: true)
        let coordinator = ReadinessCoordinator(provider: provider)
        await coordinator.setUpSpeech()
        #expect(coordinator.error == .installationFailed)
        #expect(!coordinator.isBusy)
        #expect(coordinator.snapshot.speech == .needsSetup)
    }

    @Test func externalInstallationClearsAnOldFailure() async
    {
        let provider = TestReadinessProvider(shouldFail: true)
        let coordinator = ReadinessCoordinator(provider: provider)
        await coordinator.setUpSpeech()
        await provider.setSpeech(.ready)
        await coordinator.refresh()
        #expect(coordinator.error == nil)
    }

    @Test func progressRejectsNonfiniteAndBoundsFiniteValues() async
    {
        let provider = TestReadinessProvider()
        let coordinator = ReadinessCoordinator(provider: provider)
        let operation = Task
        {
            await coordinator.setUpSpeech()
        }
        await provider.waitForProgressHandler()
        await provider.sendProgress(.infinity)
        #expect(coordinator.progress == nil)
        await provider.sendProgress(1.4)
        #expect(coordinator.progress == 1)
        await provider.sendProgress(-0.2)
        #expect(coordinator.progress == 0)
        operation.cancel()
        await operation.value
    }

    @Test func duplicateActionsCannotOverlapSetup() async
    {
        let provider = TestReadinessProvider()
        let coordinator = ReadinessCoordinator(provider: provider)
        let operation = Task
        {
            await coordinator.setUpSpeech()
        }
        await provider.waitForProgressHandler()
        await coordinator.setUpSpeech()
        await coordinator.refresh()
        #expect(await provider.setupCount == 1)
        operation.cancel()
        await operation.value
    }

    @Test func cancellationDoesNotPublishReady() async
    {
        let provider = TestReadinessProvider()
        let coordinator = ReadinessCoordinator(provider: provider)
        let operation = Task
        {
            await coordinator.setUpSpeech()
        }
        await provider.waitForProgressHandler()
        operation.cancel()
        await operation.value
        #expect(coordinator.snapshot.speech != .ready)
        #expect(coordinator.error == nil)
        #expect(!coordinator.isBusy)
    }
}
