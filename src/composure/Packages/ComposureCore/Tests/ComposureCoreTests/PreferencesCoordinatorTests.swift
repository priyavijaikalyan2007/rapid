// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 870ff273-5f4c-42b6-a40a-5756e95df8b5
// Created: 2026
// COMPONENT: Preference coordination tests
// PURPOSE: Verify onboarding commits, reset scope, and retention of unsaved choices after failures.
// RELATES: PreferencesCoordinator, PreferencesStore
// FLOW: User action -> injected store -> accepted state or retained draft and visible error.

import Testing
@testable import ComposureCore

/// Injects controlled failures without changing real application preferences.
@MainActor
struct PreferencesCoordinatorTests
{
    @Test func onboardingCompletionSavesProfileAndFlag()
    {
        let store = TestStore()
        let coordinator = makeCoordinator(store)
        coordinator.draft.profile[.needMoreCuriosity] = .important

        _ = coordinator.completeOnboarding()

        #expect(store.record?.profile[.needMoreCuriosity] == .important && store.record?.hasCompletedOnboarding == true)
    }

    @Test func savedPreferencesRestoreOnRelaunch()
    {
        let store = TestStore()
        let first = makeCoordinator(store)
        _ = first.completeOnboarding()

        let restored = makeCoordinator(store)

        #expect(restored.draft.hasCompletedOnboarding)
    }

    @Test func failedSavePreservesAcceptedState()
    {
        let store = TestStore()
        store.shouldFailSave = true
        let coordinator = makeCoordinator(store)

        _ = coordinator.completeOnboarding()

        #expect(coordinator.state == .ready(AppPreferences()))
    }

    @Test func failedSaveRetainsEditedDraft()
    {
        let store = TestStore()
        store.shouldFailSave = true
        let coordinator = makeCoordinator(store)
        coordinator.draft.profile[.overExplain] = .majorFocus

        _ = coordinator.saveDraft()

        #expect(coordinator.draft.profile[.overExplain] == .majorFocus)
    }

    @Test func failedSaveExposesControlledError()
    {
        let store = TestStore()
        store.shouldFailSave = true
        let coordinator = makeCoordinator(store)

        _ = coordinator.saveDraft()

        #expect(coordinator.saveError == .saveFailed)
    }

    @Test func retryCanSaveTheRetainedDraft()
    {
        let store = TestStore()
        store.shouldFailSave = true
        let coordinator = makeCoordinator(store)
        coordinator.draft.profile[.interruptOthers] = .important
        _ = coordinator.saveDraft()
        store.shouldFailSave = false

        _ = coordinator.saveDraft()

        #expect(store.record?.profile[.interruptOthers] == .important)
    }

    @Test func unreadablePreferencesCannotTriggerSave()
    {
        let store = TestStore()
        store.loadError = .unsupportedVersion
        let coordinator = makeCoordinator(store)

        _ = coordinator.saveDraft()

        #expect(store.saveCount == 0)
    }

    @Test func unreadablePreferencesShowUnavailableState()
    {
        let store = TestStore()
        store.loadError = .unsupportedVersion

        let coordinator = makeCoordinator(store)

        #expect(coordinator.state == .unavailable(.unsupportedVersion))
    }

    @Test func explicitResetRecoversUnreadablePreferences()
    {
        let store = TestStore()
        store.loadError = .invalidStoredData
        let coordinator = makeCoordinator(store)

        coordinator.resetAllPreferences()

        #expect(coordinator.state == .ready(AppPreferences()))
    }

    @Test func profileResetPreservesOtherPreferences()
    {
        let store = TestStore()
        var preferences = AppPreferences()
        preferences.hasCompletedOnboarding = true
        preferences.defaultSessionStyle = .highStakes
        preferences.profile[.respondTooQuickly] = .majorFocus
        store.record = preferences
        let coordinator = makeCoordinator(store)

        coordinator.resetProfile()
        preferences.profile = CoachingProfile()

        #expect(store.record == preferences)
    }

    @Test func discardingDraftRestoresAcceptedChoices()
    {
        let coordinator = makeCoordinator(TestStore())
        coordinator.draft.profile.executiveRestraint = true

        coordinator.discardChanges()

        #expect(coordinator.draft == AppPreferences())
    }

    /// Uses the production coordinator with a content-free diagnostic sink.
    private func makeCoordinator(_ store: TestStore) -> PreferencesCoordinator
    {
        PreferencesCoordinator(store: store, logger: DiagnosticLogger { _, _ in })
    }

    /// The fake models this suite's load/save failures and never stores arbitrary content.
    @MainActor
    private final class TestStore: PreferencesStore
    {
        var record: AppPreferences?
        var loadError: PreferencesError?
        var shouldFailSave = false
        var saveCount = 0

        func load() throws(PreferencesError) -> AppPreferences
        {
            if let loadError
            {
                throw loadError
            }
            return record ?? AppPreferences()
        }

        func save(_ preferences: AppPreferences) throws(PreferencesError)
        {
            saveCount += 1
            if shouldFailSave
            {
                throw .saveFailed
            }
            record = preferences
        }

        func reset()
        {
            record = nil
            loadError = nil
        }
    }
}
