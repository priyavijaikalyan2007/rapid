// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: c68fe841-14e9-4536-94fd-2c9c08402d55
// COMPONENT: Reader settings persistence tests
// PURPOSE: Preserve complete reader settings in an isolated application preferences domain.
import Foundation
import Testing
@testable import MonoMarkCore

struct ReaderPreferencesPersistenceTests
{
    @Test func sourceLineNumbersSurviveReopeningDefaults() throws
    {
        let name = "monomark-settings-test-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        var preferences = ReaderPreferences()
        preferences.showLineNumbers = true

        try preferences.store(in: defaults)
        let reopened = try #require(UserDefaults(suiteName: name))

        #expect(ReaderPreferences.forDocument(
            saved: nil, defaultsData: reopened.data(forKey: "reader-defaults")
        ).showLineNumbers)
    }

    @Test func completeSettingsSurviveReopeningDefaults() throws
    {
        let name = "monomark-settings-test-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = completeSettings()

        try preferences.store(in: defaults)
        let reopened = try #require(UserDefaults(suiteName: name))

        #expect(ReaderPreferences.forDocument(
            saved: nil, defaultsData: reopened.data(forKey: "reader-defaults")
        ) == preferences)
    }

    private func completeSettings() -> ReaderPreferences
    {
        var preferences = ReaderPreferences()
        preferences.fontFamily = "JetBrains Mono"
        preferences.headingFontFamily = "Atkinson Hyperlegible"
        preferences.codeFontFamily = "Menlo"
        preferences.tableFontFamily = "Monaco"
        preferences.captionFontFamily = "Courier"
        preferences.bodySize = 19
        preferences.headingSizes = [36, 31, 27, 23, 19, 17]
        preferences.codeSize = 16
        preferences.tableSize = 17
        preferences.captionSize = 15
        preferences.lineHeight = 1.8
        preferences.pageWidth = 800
        preferences.autoReload = false
        preferences.showLineNumbers = true
        preferences.preserveLineBreaks = true
        preferences.implicitFileLinks = true
        preferences.implicitSectionLinks = true
        preferences.layoutMode = "pages"
        preferences.paperSize = "a4"
        preferences.columnBanding = true
        preferences.palette.preset("forest", dark: true)
        preferences.palette.preset("ocean", dark: false)
        return preferences
    }

    @Test func persistedSettingsNormalizeBeforeEncoding() throws
    {
        let name = "monomark-settings-test-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        var preferences = ReaderPreferences()
        preferences.bodySize = .nan
        preferences.layoutMode = "invalid"

        try preferences.store(in: defaults)

        #expect(ReaderPreferences.forDocument(
            saved: nil, defaultsData: defaults.data(forKey: "reader-defaults")
        ) == ReaderPreferences())
    }
}
