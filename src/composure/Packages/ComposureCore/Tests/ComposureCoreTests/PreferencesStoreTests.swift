// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4260dfac-c7b9-4ef3-bf12-ac5cc767bfc6
// Created: 2026
// COMPONENT: Typed preference storage tests
// PURPOSE: Verify real UserDefaults round trips, schema rejection, and reset ownership.
// RELATES: UserDefaultsPreferencesStore
// FLOW: Isolated preference domain -> bounded record -> typed state or controlled error.

import Foundation
import Testing
@testable import ComposureCore

/// Every case owns a separate synthetic defaults domain and removes it after the test.
@MainActor
struct PreferencesStoreTests
{
    @Test func firstReadDoesNotWriteDefaults() throws
    {
        try withDefaults
        { defaults, domain in
            _ = try UserDefaultsPreferencesStore(defaults: defaults).load()

            #expect((defaults.persistentDomain(forName: domain) ?? [:]).isEmpty)
        }
    }

    @Test func newStoreRestoresProfileAndOnboarding() throws
    {
        try withDefaults
        { defaults, _ in
            var preferences = AppPreferences()
            preferences.profile[.becomeDefensive] = .majorFocus
            preferences.hasCompletedOnboarding = true
            try UserDefaultsPreferencesStore(defaults: defaults).save(preferences)

            let restored = try UserDefaultsPreferencesStore(defaults: defaults).load()

            #expect(restored == preferences)
        }
    }

    @Test func storeWritesOnlyItsOwnedRecord() throws
    {
        try withDefaults
        { defaults, domain in
            try UserDefaultsPreferencesStore(defaults: defaults).save(AppPreferences())

            let stored = defaults.persistentDomain(forName: domain) ?? [:]
            #expect(Set(stored.keys) == [UserDefaultsPreferencesStore.storageKey])
        }
    }

    @Test func corruptRecordIsReported() throws
    {
        try withDefaults
        { defaults, _ in
            defaults.set(Data("synthetic invalid record".utf8), forKey: UserDefaultsPreferencesStore.storageKey)

            #expect(throws: PreferencesError.invalidStoredData)
            {
                try UserDefaultsPreferencesStore(defaults: defaults).load()
            }
        }
    }

    @Test func corruptRecordCannotBeOverwritten() throws
    {
        try withDefaults
        { defaults, _ in
            let marker = Data("synthetic invalid record".utf8)
            defaults.set(marker, forKey: UserDefaultsPreferencesStore.storageKey)

            _ = try? UserDefaultsPreferencesStore(defaults: defaults).save(AppPreferences())

            #expect(defaults.data(forKey: UserDefaultsPreferencesStore.storageKey) == marker)
        }
    }

    @Test func futureVersionIsReportedBeforeDecodingFields() throws
    {
        try withDefaults
        { defaults, _ in
            let future = Data("{\"version\":99,\"preferences\":{}}".utf8)
            defaults.set(future, forKey: UserDefaultsPreferencesStore.storageKey)

            #expect(throws: PreferencesError.unsupportedVersion)
            {
                try UserDefaultsPreferencesStore(defaults: defaults).load()
            }
        }
    }

    @Test func futureVersionCannotBeOverwritten() throws
    {
        try withDefaults
        { defaults, _ in
            let future = Data("{\"version\":99,\"preferences\":{}}".utf8)
            defaults.set(future, forKey: UserDefaultsPreferencesStore.storageKey)

            _ = try? UserDefaultsPreferencesStore(defaults: defaults).save(AppPreferences())

            #expect(defaults.data(forKey: UserDefaultsPreferencesStore.storageKey) == future)
        }
    }

    @Test func wrongStoredTypeIsReported() throws
    {
        try withDefaults
        { defaults, _ in
            defaults.set("synthetic wrong type", forKey: UserDefaultsPreferencesStore.storageKey)

            #expect(throws: PreferencesError.invalidStoredData)
            {
                try UserDefaultsPreferencesStore(defaults: defaults).load()
            }
        }
    }

    @Test func oversizedRecordIsRejectedBeforeDecoding() throws
    {
        try withDefaults
        { defaults, _ in
            let oversized = Data(repeating: 32, count: UserDefaultsPreferencesStore.maximumRecordBytes + 1)
            defaults.set(oversized, forKey: UserDefaultsPreferencesStore.storageKey)

            #expect(throws: PreferencesError.invalidStoredData)
            {
                try UserDefaultsPreferencesStore(defaults: defaults).load()
            }
        }
    }

    @Test func resetPreservesUnrelatedPreferences() throws
    {
        try withDefaults
        { defaults, _ in
            defaults.set(true, forKey: "unrelated.preference")
            let store = UserDefaultsPreferencesStore(defaults: defaults)
            try store.save(AppPreferences())

            store.reset()

            #expect(defaults.bool(forKey: "unrelated.preference"))
        }
    }

    @Test func resetRestoresFirstRunState() throws
    {
        try withDefaults
        { defaults, _ in
            let store = UserDefaultsPreferencesStore(defaults: defaults)
            defaults.set(Data("synthetic corrupt record".utf8), forKey: UserDefaultsPreferencesStore.storageKey)

            store.reset()

            let restored = try store.load()
            #expect(restored == AppPreferences())
        }
    }

    /// Keeps test writes outside the real app domain and never inspects global preferences.
    private func withDefaults(_ operation: (UserDefaults, String) throws -> Void) throws
    {
        let domain = "us.outcrop.composure.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        try operation(defaults, domain)
    }
}
