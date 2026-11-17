// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 0b2ad2d3-fd80-4025-8df4-26de953424aa
// Created: 2026
// COMPONENT: MonoMark core
// PURPOSE: Keep reading preferences bounded and serializable.
// RELATES: MonoMarkCoreTests
// FLOW: Validated input -> local processing -> typed result.

import Foundation

/// Bounded document appearance. Family names are data, never executable CSS.
struct ReaderPreferences: Codable, Equatable, Sendable
{
    var palette = ReaderPalette()
    var fontFamily = "ui-monospace"
    var headingFontFamily = ""
    var codeFontFamily = ""
    var tableFontFamily = ""
    var captionFontFamily = ""
    var bodySize = 15.0
    var headingSizes = [30.0, 25.0, 21.0, 18.0, 16.0, 15.0]
    var codeSize = 14.0
    var tableSize = 14.0
    var captionSize = 13.0
    var lineHeight = 1.65
    var pageWidth = 960.0
    var columnBanding = false
    var preserveLineBreaks = false
    var showLineNumbers = false
    var autoReload = true
    var paperSize = "system"
    var layoutMode = "pageless"

    init()
    {
    }

    private enum CodingKeys: String, CodingKey
    {
        case fontFamily, headingFontFamily, codeFontFamily, tableFontFamily, captionFontFamily
        case paperSize, layoutMode, palette
        case preserveLineBreaks, showLineNumbers, autoReload
        case bodySize, headingSizes, codeSize, tableSize, captionSize, lineHeight, pageWidth, columnBanding
    }

    /// Older preference records inherit newly added fields instead of losing reading-state recovery.
    init(from decoder: Decoder) throws
    {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fontFamily = try values.decodeIfPresent(String.self, forKey: .fontFamily) ?? "ui-monospace"
        headingFontFamily = try values.decodeIfPresent(String.self, forKey: .headingFontFamily) ?? ""
        codeFontFamily = try values.decodeIfPresent(String.self, forKey: .codeFontFamily) ?? ""
        tableFontFamily = try values.decodeIfPresent(String.self, forKey: .tableFontFamily) ?? ""
        captionFontFamily = try values.decodeIfPresent(String.self, forKey: .captionFontFamily) ?? ""
        bodySize = try values.decodeIfPresent(Double.self, forKey: .bodySize) ?? 15
        headingSizes = try values.decodeIfPresent([Double].self, forKey: .headingSizes) ?? headingSizes
        codeSize = try values.decodeIfPresent(Double.self, forKey: .codeSize) ?? 14
        tableSize = try values.decodeIfPresent(Double.self, forKey: .tableSize) ?? 14
        captionSize = try values.decodeIfPresent(Double.self, forKey: .captionSize) ?? 13
        lineHeight = try values.decodeIfPresent(Double.self, forKey: .lineHeight) ?? 1.65
        pageWidth = try values.decodeIfPresent(Double.self, forKey: .pageWidth) ?? 960
        columnBanding = try values.decodeIfPresent(Bool.self, forKey: .columnBanding) ?? false
        preserveLineBreaks = try values.decodeIfPresent(Bool.self, forKey: .preserveLineBreaks) ?? false
        showLineNumbers = try values.decodeIfPresent(Bool.self, forKey: .showLineNumbers) ?? false
        autoReload = try values.decodeIfPresent(Bool.self, forKey: .autoReload) ?? true
        paperSize = try values.decodeIfPresent(String.self, forKey: .paperSize) ?? "system"
        layoutMode = try values.decodeIfPresent(String.self, forKey: .layoutMode) ?? "pageless"
        palette = try values.decodeIfPresent(ReaderPalette.self, forKey: .palette) ?? ReaderPalette()
        normalize()
    }

    /// Normalize persisted values before applying them to native or web views.
    mutating func normalize()
    {
        palette.normalize()
        if !["system", "a4", "letter", "legal"].contains(paperSize)
        {
            paperSize = "system"
        }
        if !["pages", "pageless"].contains(layoutMode)
        {
            layoutMode = "pageless"
        }
        fontFamily = Self.safeFamily(fontFamily, fallback: "ui-monospace")
        headingFontFamily = Self.safeFamily(headingFontFamily)
        codeFontFamily = Self.safeFamily(codeFontFamily)
        tableFontFamily = Self.safeFamily(tableFontFamily)
        captionFontFamily = Self.safeFamily(captionFontFamily)
        bodySize = Self.bound(bodySize, 9 ... 48, fallback: 15)
        headingSizes = (0 ..< 6).map
        { index in
            Self.bound(headingSizes.indices.contains(index) ? headingSizes[index] : 20, 10 ... 80, fallback: 20)
        }
        codeSize = Self.bound(codeSize, 9 ... 40, fallback: 14)
        tableSize = Self.bound(tableSize, 9 ... 40, fallback: 14)
        captionSize = Self.bound(captionSize, 9 ... 40, fallback: 13)
        lineHeight = Self.bound(lineHeight, 1.1 ... 2.5, fallback: 1.65)
        pageWidth = Self.bound(pageWidth, 320 ... 1800, fallback: 960)
    }

    /// New documents inherit explicit app defaults. Existing document overrides always take precedence.
    static func forDocument(saved: ReaderPreferences?, defaultsData: Data?) -> ReaderPreferences
    {
        var result = saved ?? defaultsData.flatMap
        {
            try? JSONDecoder().decode(Self.self, from: $0)
        } ?? Self()
        result.normalize()
        return result
    }

    private static func safeFamily(_ value: String, fallback: String = "") -> String
    {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -_"))
        if value.isEmpty || value.count > 80 || value.unicodeScalars.contains(where: {
            !allowed.contains($0)
        })
        {
            return fallback
        }
        return value
    }

    static func bound(_ value: Double, _ range: ClosedRange<Double>, fallback: Double) -> Double
    {
        value.isFinite ? min(max(value, range.lowerBound), range.upperBound) : fallback
    }
}
