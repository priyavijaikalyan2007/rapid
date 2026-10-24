// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 17a3791f-3d39-4eae-b644-a92e47c768f5
// Created: 2026
// COMPONENT: PrintSheetSettings
// PURPOSE: Defines the PrintSheetSettings domain values and their contracts.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PrintSheetSettings -> local result.

import CoreGraphics
import Foundation

/// Defines the PrintSheetSettings domain values and their contracts.
struct PrintSheetSettings
{
    /// Selected physical paper size in inches.
    var paperSize: PaperSize = .fiveBySeven
    /// Paper orientation used by PrintSheetSettings.
    var paperOrientation: PrintOrientation = .portrait
    /// Resolution used by PrintSheetSettings.
    var resolution: PrintSheetResolution = .ppi300
    /// Printer resolution used by PrintSheetSettings.
    var printerResolution: PrinterResolution = .dpi300
    /// Includes cut guides used by PrintSheetSettings.
    var includesCutGuides = true
    /// Unused paper border measured in inches and validated as nonnegative.
    var edgeInsetInches: CGFloat = 0.125
    /// Space between printed copies measured in inches and validated as nonnegative.
    var gutterInches: CGFloat = 0.125
}
