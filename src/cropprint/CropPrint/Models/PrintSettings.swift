// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: cbfe52f4-cf8f-4bc3-b084-8d16332787ce
// Created: 2026
// COMPONENT: PrintSettings
// PURPOSE: Stores crop preset, orientation, paper, and guide choices.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PrintSettings -> local result.

import CoreGraphics
import Foundation

/// Stores crop preset, orientation, paper, and guide choices.
struct PrintSettings
{
    /// Selected crop dimensions and category.
    var preset: CropPreset = .fourBySix
    /// Portrait or landscape orientation where the preset supports rotation.
    var orientation: PrintOrientation = .portrait
    /// Selected physical paper size in inches.
    var paperSize: PaperSize = .postcard
    /// Adds a quarter-inch white margin inside supported print presets.
    var includesMargin = false
    /// Displays visual passport alignment guidance without changing export pixels.
    var showsPassportGuide = true

    /// Selected crop width divided by height.
    var aspectRatio: CGFloat
    {
        preset.aspectRatio(for: orientation)
    }

    /// Is print preset used by PrintSettings.
    var isPrintPreset: Bool
    {
        preset.category == .print
    }

    /// Is passport preset used by PrintSettings.
    var isPassportPreset: Bool
    {
        preset.category == .passport
    }

    /// Exact digital export dimensions, or nil for source-resolution print presets.
    var outputPixels: CGSize?
    {
        guard preset.targetPixels != nil
        else
        {
            return nil
        }
        return preset.dimensions(for: orientation)
    }

    /// Stable filename label for the selected export options.
    var fileSuffix: String
    {
        if isPrintPreset
        {
            let margin = includesMargin ? "margin" : "no-margin"
            return "\(preset.fileLabel)-\(orientation.rawValue)-\(paperSize.fileLabel)-\(margin)"
        }
        if preset.supportsOrientation
        {
            return "\(preset.fileLabel)-\(orientation.rawValue)"
        }
        return preset.fileLabel
    }

    /// Indicates whether the selected physical photo fits the oriented paper.
    var fitsPaper: Bool
    {
        guard let physicalSize = preset.physicalInches
        else
        {
            return true
        }
        let photo = orientation == .portrait
            ? physicalSize
            : CGSize(width: physicalSize.height, height: physicalSize.width)
        let paper = paperSize.orientedSize(for: orientation)
        return photo.width <= paper.width && photo.height <= paper.height
    }
}
