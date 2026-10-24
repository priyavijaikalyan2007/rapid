// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 193af4e7-cddc-432e-bb76-dcefa78102c0
// Created: 2026
// COMPONENT: App-owned defaults adapter
// PURPOSE: Persist one bounded preference record while preserving unreadable or future records.
// RELATES: PreferencesRecord, PreferencesStore
// FLOW: App-owned key -> bounded decoding or typed encoding -> UserDefaults.

import Foundation

/// Uses app-only defaults. UserDefaults writes its in-memory changes to disk asynchronously.
@MainActor
public final class UserDefaultsPreferencesStore: PreferencesStore
{
    static let storageKey = "composure.preferences"
    static let maximumRecordBytes = 16 * 1024
    private let defaults: UserDefaults

    /// The composition root supplies the app domain. Tests supply isolated synthetic domains.
    public init(defaults: UserDefaults)
    {
        self.defaults = defaults
    }

    public func load() throws(PreferencesError) -> AppPreferences
    {
        guard let stored = defaults.object(forKey: Self.storageKey)
        else
        {
            return AppPreferences()
        }
        guard let encoded = stored as? Data, encoded.count <= Self.maximumRecordBytes
        else
        {
            throw .invalidStoredData
        }
        return try decode(encoded)
    }

    /// A failed prior read blocks normal writes until an explicit reset or successful recovery.
    public func save(_ preferences: AppPreferences) throws(PreferencesError)
    {
        _ = try load()
        let encoded: Data
        do
        {
            encoded = try JSONEncoder().encode(PreferencesRecord(preferences: preferences))
        }
        catch
        {
            throw .saveFailed
        }
        guard encoded.count <= Self.maximumRecordBytes
        else
        {
            throw .saveFailed
        }
        defaults.set(encoded, forKey: Self.storageKey)
    }

    /// Removes only the owned preference record, never the whole defaults domain.
    public func reset()
    {
        defaults.removeObject(forKey: Self.storageKey)
    }

    private func decode(_ encoded: Data) throws(PreferencesError) -> AppPreferences
    {
        do
        {
            return try JSONDecoder().decode(PreferencesRecord.self, from: encoded).preferences
        }
        catch let error as PreferencesError
        {
            throw error
        }
        catch
        {
            throw .invalidStoredData
        }
    }
}
