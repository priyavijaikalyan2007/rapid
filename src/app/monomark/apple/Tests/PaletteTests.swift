// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 26bb76d5-e9d0-4497-b8c0-ec87e73f9718
// COMPONENT: Reader palette contracts
// PURPOSE: Verify adaptive swatches, contrast, independent modes, and preference recovery.
import Foundation
import Testing
@testable import MonoMarkCore

struct PaletteTests
{
    @Test func defaultPalettesCoverEveryRole() throws
    {
        let palette = ReaderPalette()
        for dark in [false, true]
        {
            #expect(palette.resolve(dark: dark).count == PaletteRole.allCases.count)
            #expect(palette.resolve(dark: dark)["heading1"] != palette.resolve(dark: !dark)["heading1"])
        }
    }

    @Test func swatchesStayReadableAgainstEverySurface() throws
    {
        for dark in [false, true]
        {
            for foreground in PaletteSwatch.allCases
            {
                for background in PaletteSwatch.allCases
                {
                    var palette = ReaderPalette()
                    palette.set(role: .tableText, choice: foreground.rawValue, dark: dark)
                    for role in [PaletteRole.tableBackground, .tableHeaderBackground, .rowAlternate, .columnAlternate]
                    {
                        palette.set(role: role, choice: background.rawValue, dark: dark)
                    }
                    let values = palette.resolve(dark: dark)
                    for role in ["tableBackground", "tableHeaderBackground", "rowAlternate", "columnAlternate"]
                    {
                        #expect(PaletteContrast.ratio(values["tableText"]!, values[role]!) >= 4.5)
                    }
                }
            }
        }
    }

    @Test func changesAndResetAffectOnlyTheChosenMode() throws
    {
        var palette = ReaderPalette()
        let dark = palette.resolve(dark: true)
        let original = palette.resolve(dark: false)
        palette.set(role: .heading1, choice: "purple", dark: false)
        #expect(palette.resolve(dark: false)["heading1"] != original["heading1"])
        #expect(palette.resolve(dark: true) == dark)
        palette.reset(dark: false)
        #expect(palette.resolve(dark: false) == original)
    }

    @Test func untrustedChoicesAreRemovedBeforeUse() throws
    {
        var palette = ReaderPalette()
        palette.light = ["heading1": "url(https://example.invalid)", "unknown": "blue"]
        palette.dark = ["equation": "teal"]
        palette.normalize()
        #expect(palette.light.isEmpty)
        #expect(palette.dark["equation"] == "teal")
        #expect(palette.resolve(dark: false) == ReaderPalette().resolve(dark: false))
    }

    @Test func preferencesPreservePalettesAndRecoverOlderRecords() throws
    {
        var preferences = ReaderPreferences()
        preferences.palette.set(role: .caption, choice: "purple", dark: true)
        let data = try JSONEncoder().encode(preferences)
        let restored = try JSONDecoder().decode(ReaderPreferences.self, from: data)
        #expect(restored.palette == preferences.palette)
        #expect(try JSONDecoder().decode(ReaderPreferences.self, from: Data("{}".utf8)).palette == ReaderPalette())
    }

    @Test func presetsAndContrastHaveDeterministicResults() throws
    {
        var palette = ReaderPalette()
        palette.preset("forest", dark: false)
        #expect(palette.choice(role: .heading1, dark: false) == "green")
        palette.preset("neutral", dark: true)
        #expect(palette.choice(role: .heading2, dark: true) == "neutral")
        palette.preset("invalid", dark: false)
        #expect(palette.resolve(dark: false) == ReaderPalette().resolve(dark: false))
        #expect(abs(PaletteContrast.ratio("#000000", "#ffffff") - 21) < 0.001)
        #expect(PaletteContrast.ratio("invalid", "#ffffff") == 1)
    }
}
