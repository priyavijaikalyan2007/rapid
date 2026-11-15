// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: bb22729c-7765-4bf5-b4bb-5407a8f32aa4
// COMPONENT: Persisted reader palette
// PURPOSE: Keep separate adaptive choices and enforce readable text on every selected surface.
import Foundation

struct ReaderPalette: Codable, Equatable, Sendable
{
    var light: [String: String] = [:]
    var dark: [String: String] = [:]

    mutating func normalize()
    {
        light = light.filter
        {
            PaletteRole(rawValue: $0.key) != nil && PaletteSwatch(rawValue: $0.value) != nil
        }
        dark = dark.filter
        {
            PaletteRole(rawValue: $0.key) != nil && PaletteSwatch(rawValue: $0.value) != nil
        }
    }

    func choice(role: PaletteRole, dark isDark: Bool) -> String
    {
        let value = (isDark ? dark : light)[role.rawValue] ?? ""
        return PaletteSwatch(rawValue: value)?.rawValue ?? role.defaultChoice.rawValue
    }

    mutating func set(role: PaletteRole, choice: String, dark isDark: Bool)
    {
        guard PaletteSwatch(rawValue: choice) != nil
        else
        {
            return
        }
        if isDark
        {
            dark[role.rawValue] = choice
        }
        else
        {
            light[role.rawValue] = choice
        }
    }

    mutating func reset(dark isDark: Bool)
    {
        if isDark
        {
            dark = [:]
        }
        else
        {
            light = [:]
        }
    }

    mutating func preset(_ name: String, dark: Bool)
    {
        reset(dark: dark)
        let swatch: String
        switch name
        {
        case "forest": swatch = "green"
        case "ocean": swatch = "blue"
        case "neutral": swatch = "neutral"
        default: return
        }
        for role in PaletteRole.allCases where !role.isSurface && role != .tableText
        {
            set(role: role, choice: swatch, dark: dark)
        }
    }

    func resolve(dark: Bool) -> [String: String]
    {
        var result = Dictionary(uniqueKeysWithValues: PaletteRole.allCases.map
        {
            let swatch = PaletteSwatch(rawValue: choice(role: $0, dark: dark)) ?? $0.defaultChoice
            return ($0.rawValue, swatch.hex(dark: dark, surface: $0.isSurface))
        })
        for role in PaletteRole.allCases where !role.isSurface
        {
            let color = result[role.rawValue] ?? ""
            if backgrounds(role: role, dark: dark, values: result)
                .contains(where: {
                    PaletteContrast.ratio(color, $0) < 4.5
                })
            {
                result[role.rawValue] = dark ? "#ffffff" : "#000000"
            }
        }
        return result
    }

    private func backgrounds(role: PaletteRole, dark: Bool, values: [String: String]) -> [String]
    {
        if role == .tableText
        {
            return [PaletteRole.tableBackground, .tableHeaderBackground, .rowAlternate, .columnAlternate].compactMap
            {
                values[$0.rawValue]
            }
        }
        if role == .calloutText || role == .calloutBorder
        {
            return [values[PaletteRole.calloutBackground.rawValue] ?? ""]
        }
        return [PaletteSwatch.neutral.hex(dark: dark, surface: true)]
    }
}
