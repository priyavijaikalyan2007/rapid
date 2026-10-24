// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: ebdf7510-5900-4b98-b104-c725f9e77630
// Created: 2026
// COMPONENT: PrintSheetResolution
// PURPOSE: Lists image sampling densities used to calculate print-sheet raster pixels.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PrintSheetResolution -> local result.

import CoreGraphics
import Foundation

/// Lists image sampling densities used to calculate print-sheet raster pixels.
enum PrintSheetResolution: Int, CaseIterable, Identifiable
{
    /// Selects ppi72 within this type's supported choices.
    case ppi72 = 72
    /// Selects ppi96 within this type's supported choices.
    case ppi96 = 96
    /// Selects ppi150 within this type's supported choices.
    case ppi150 = 150
    /// Selects ppi200 within this type's supported choices.
    case ppi200 = 200
    /// Selects ppi240 within this type's supported choices.
    case ppi240 = 240
    /// Selects ppi300 within this type's supported choices.
    case ppi300 = 300
    /// Selects ppi360 within this type's supported choices.
    case ppi360 = 360
    /// Selects ppi600 within this type's supported choices.
    case ppi600 = 600
    /// Selects ppi720 within this type's supported choices.
    case ppi720 = 720
    /// Selects ppi1200 within this type's supported choices.
    case ppi1200 = 1200

    /// Identity used by native selection controls.
    var id: Self
    {
        self
    }

    /// User-facing label displayed by the native selection controls.
    var title: String
    {
        "\(rawValue) PPI"
    }
}
