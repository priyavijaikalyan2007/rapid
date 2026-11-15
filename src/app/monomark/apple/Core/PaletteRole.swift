// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: b9737b9d-a7db-41c5-986f-60703033001c
// COMPONENT: Reader color roles
// PURPOSE: Name supported reader elements independently of native or CSS controls.
import Foundation

enum PaletteRole: String, CaseIterable, Sendable
{
    case heading1, heading2, heading3, heading4, heading5, heading6
    case caption, equation, calloutText, calloutBackground, calloutBorder
    case tableText, tableBackground, tableHeaderBackground, rowAlternate, columnAlternate

    var label: String
    {
        switch self
        {
        case .heading1: "Heading 1"
        case .heading2: "Heading 2"
        case .heading3: "Heading 3"
        case .heading4: "Heading 4"
        case .heading5: "Heading 5"
        case .heading6: "Heading 6"
        case .caption: "Captions"
        case .equation: "Equations"
        case .calloutText: "Callout text"
        case .calloutBackground: "Callout background"
        case .calloutBorder: "Callout border"
        case .tableText: "Table text"
        case .tableBackground: "Table background"
        case .tableHeaderBackground: "Table header background"
        case .rowAlternate: "Alternate rows"
        case .columnAlternate: "Alternate columns"
        }
    }

    var isSurface: Bool
    {
        [.calloutBackground, .tableBackground, .tableHeaderBackground, .rowAlternate, .columnAlternate].contains(self)
    }

    var defaultChoice: PaletteSwatch
    {
        switch self
        {
        case .heading1, .heading4, .calloutBackground, .calloutBorder, .columnAlternate: .blue
        case .heading2, .equation: .purple
        case .heading3: .teal
        case .caption, .tableHeaderBackground, .rowAlternate: .gray
        default: .neutral
        }
    }
}
