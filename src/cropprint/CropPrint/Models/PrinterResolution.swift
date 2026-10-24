// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f77d0087-1e01-4350-8f86-621ff6838716
// Created: 2026
// COMPONENT: PrinterResolution
// PURPOSE: Lists printer dot densities separately from image sampling density.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PrinterResolution -> local result.

import CoreGraphics
import Foundation

/// Lists printer dot densities separately from image sampling density.
enum PrinterResolution: Int, CaseIterable, Identifiable
{
    /// Selects dpi300 within this type's supported choices.
    case dpi300 = 300
    /// Selects dpi600 within this type's supported choices.
    case dpi600 = 600
    /// Selects dpi720 within this type's supported choices.
    case dpi720 = 720
    /// Selects dpi1200 within this type's supported choices.
    case dpi1200 = 1200
    /// Selects dpi1440 within this type's supported choices.
    case dpi1440 = 1440
    /// Selects dpi2400 within this type's supported choices.
    case dpi2400 = 2400
    /// Selects dpi4800 within this type's supported choices.
    case dpi4800 = 4800

    /// Identity used by native selection controls.
    var id: Self
    {
        self
    }

    /// User-facing label displayed by the native selection controls.
    var title: String
    {
        "\(rawValue) DPI"
    }
}
