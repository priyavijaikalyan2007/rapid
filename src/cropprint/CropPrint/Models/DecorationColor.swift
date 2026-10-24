// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a335f8f7-55a3-4c14-b27a-b0d1bf3be65d
// Created: 2026
// COMPONENT: DecorationColor
// PURPOSE: Keeps native preview palette colors consistent with sRGB export colors.
// RELATES: [[CropPrint]]
// FLOW: Native application -> DecorationColor -> local result.

import SwiftUI

/// Keeps native preview palette colors consistent with sRGB export colors.
enum DecorationColor: String, CaseIterable, Identifiable
{
    /// Selects white within this type's supported choices.
    case white
    /// Selects black within this type's supported choices.
    case black
    /// Selects red within this type's supported choices.
    case red
    /// Selects blue within this type's supported choices.
    case blue
    /// Selects gold within this type's supported choices.
    case gold

    /// Identity used by native selection controls.
    var id: Self
    {
        self
    }

    /// User-facing label displayed by the native selection controls.
    var title: String
    {
        rawValue.capitalized
    }

    /// Color used by DecorationColor.
    var color: Color
    {
        switch self
        {
        case .white: .white
        case .black: .black
        case .red: Color(red: 0.86, green: 0.12, blue: 0.16)
        case .blue: Color(red: 0.10, green: 0.38, blue: 0.82)
        case .gold: Color(red: 0.88, green: 0.66, blue: 0.12)
        }
    }

    /// Explicit sRGB color matching the native preview palette during export.
    var cgColor: CGColor
    {
        switch self
        {
        case .white: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        case .black: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        case .red: CGColor(srgbRed: 0.86, green: 0.12, blue: 0.16, alpha: 1)
        case .blue: CGColor(srgbRed: 0.10, green: 0.38, blue: 0.82, alpha: 1)
        case .gold: CGColor(srgbRed: 0.88, green: 0.66, blue: 0.12, alpha: 1)
        }
    }
}
