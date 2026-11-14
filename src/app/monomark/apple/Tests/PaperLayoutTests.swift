// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: b5e84bbf-62b4-47c7-9625-15400d7f306c
// COMPONENT: Paper preferences and print geometry contracts
// PURPOSE: Verify physical paper sizes and backward-compatible per-document preferences.
import Foundation
import Testing
@testable import MonoMarkCore

struct PaperLayoutTests
{
    @Test func standardSizesUsePrinterPoints() throws
    {
        #expect(PaperLayout.resolve("letter").widthPoints == 612)
        #expect(PaperLayout.resolve("letter").heightPoints == 792)
        #expect(PaperLayout.resolve("legal").heightPoints == 1008)
        #expect(abs(PaperLayout.resolve("a4").widthPoints - 595.276) < 0.01)
    }

    @Test func systemPaperPreservesTheProvidedOrientation() throws
    {
        let paper = PaperLayout.resolve("system", systemWidth: 792, systemHeight: 612)
        #expect(paper.widthPoints == 792)
        #expect(paper.heightPoints == 612)
    }

    @Test func invalidSystemGeometryFallsBackSafely() throws
    {
        #expect(PaperLayout.resolve("system", systemWidth: .nan, systemHeight: -1).widthPoints > 500)
    }

    @Test func layoutPreferencesRoundTripAndOlderRecordsRemainPageless() throws
    {
        var preferences = ReaderPreferences()
        preferences.paperSize = "legal"
        preferences.layoutMode = "pages"
        let data = try JSONEncoder().encode(preferences)
        let saved = try JSONDecoder().decode(ReaderPreferences.self, from: data)
        #expect(saved.paperSize == "legal")
        #expect(saved.layoutMode == "pages")
        #expect(try JSONDecoder().decode(ReaderPreferences.self, from: Data("{}".utf8)).layoutMode == "pageless")
        preferences.layoutMode = "invalid"
        preferences.paperSize = "invalid"
        preferences.normalize()
        #expect(preferences.layoutMode == "pageless")
        #expect(preferences.paperSize == "system")
    }
}
