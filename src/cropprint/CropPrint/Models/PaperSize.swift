// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4e92126b-aeaf-49ae-b6e2-a404927c37e1
// Created: 2026
// COMPONENT: PaperSize
// PURPOSE: Defines physical paper dimensions and safe filename labels.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PaperSize -> local result.

import CoreGraphics
import Foundation

/// Defines physical paper dimensions and safe filename labels.
enum PaperSize: String, CaseIterable, Identifiable
{
    /// Represents postcard with its associated contract value.
    case postcard = "Postcard (4x6)"
    /// Selects five by seven within this type's supported choices.
    case fiveBySeven = "5x7"
    /// Selects eight by ten within this type's supported choices.
    case eightByTen = "8x10"
    /// Selects letter within this type's supported choices.
    case letter = "Letter"
    /// Selects a4 within this type's supported choices.
    case a4 = "A4"
    /// Selects ten by fourteen within this type's supported choices.
    case tenByFourteen = "10x14"
    /// Selects twenty four by thirty six within this type's supported choices.
    case twentyFourByThirtySix = "24x36"

    /// Identity used by native selection controls.
    var id: Self
    {
        self
    }

    /// File label used by PaperSize.
    var fileLabel: String
    {
        switch self
        {
        case .postcard: "postcard"
        case .fiveBySeven: "5x7-paper"
        case .eightByTen: "8x10-paper"
        case .letter: "letter"
        case .a4: "a4"
        case .tenByFourteen: "10x14-paper"
        case .twentyFourByThirtySix: "24x36-paper"
        }
    }

    /// Inches used by PaperSize.
    var inches: CGSize
    {
        switch self
        {
        case .postcard: CGSize(width: 4, height: 6)
        case .fiveBySeven: CGSize(width: 5, height: 7)
        case .eightByTen: CGSize(width: 8, height: 10)
        case .letter: CGSize(width: 8.5, height: 11)
        case .a4: CGSize(width: 8.27, height: 11.69)
        case .tenByFourteen: CGSize(width: 10, height: 14)
        case .twentyFourByThirtySix: CGSize(width: 24, height: 36)
        }
    }

    /// Returns paper dimensions in inches for the selected orientation.
    func orientedSize(for orientation: PrintOrientation) -> CGSize
    {
        orientation == .portrait ? inches : CGSize(width: inches.height, height: inches.width)
    }
}
