// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9b36cba2-ea15-4e76-84be-172d31349d7a
// Created: 2026
// COMPONENT: PrintSheetOutput
// PURPOSE: Identifies completed sheet files and the number of physical photo copies.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PrintSheetOutput -> local result.

import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Identifies completed sheet files and the number of physical photo copies.
struct PrintSheetOutput
{
    /// Completed raster sheet, or nil when only a safe vector PDF could be produced.
    let jpegURL: URL?
    /// Completed PDF whose page geometry preserves the selected physical paper size.
    let pdfURL: URL
    /// Number of whole photo placements in this layout.
    let copyCount: Int
}
