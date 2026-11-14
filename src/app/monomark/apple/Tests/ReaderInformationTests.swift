// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 7ae1cc09-98fc-46ad-997f-64c1b011e5e0
// COMPONENT: Application information contracts
// PURPOSE: Verify version metadata and locally available help topics.
import Foundation
import Testing
@testable import MonoMarkCore

struct ReaderInformationTests
{
    @Test func includesVersionBuildAndCopyright() throws
    {
        let information = ReaderInformation(metadata: [
            "CFBundleShortVersionString": "0.2.0",
            "CFBundleVersion": "42",
            "MonoMarkGitSHA": "abc123"
        ])
        #expect(information.versionDescription.contains("0.2.0"))
        #expect(information.versionDescription.contains("42"))
        #expect(information.versionDescription.contains("abc123"))
        #expect(information.copyright.contains("Outcrop Inc"))
    }

    @Test func missingBuildMetadataIsExplicit() throws
    {
        #expect(ReaderInformation(metadata: [:]).versionDescription.contains("development"))
    }

    @Test func helpExplainsLocalStorageAndExplicitExport() throws
    {
        let content = ReaderInformation.help.map
        {
            $0.title + " " + $0.detail
        }.joined(separator: " ")
        #expect(content.contains("Application Support"))
        #expect(content.contains("Export a Copy"))
        #expect(content.contains("history"))
        #expect(content.contains("Markdown"))
    }

    @Test func fontChoicesPreserveInstalledFamiliesAndCurrentChoice() throws
    {
        let choices = FontChoices.make(
            installed: ["JetBrains Mono", "Atkinson Hyperlegible", "JetBrains Mono"],
            current: "Missing Font"
        )
        #expect(choices.contains("JetBrains Mono"))
        #expect(choices.contains("Atkinson Hyperlegible"))
        #expect(choices.contains("Missing Font"))
        #expect(choices.filter
        {
            $0 == "JetBrains Mono"
        }.count == 1)
    }
}
