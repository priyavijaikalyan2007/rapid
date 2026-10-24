// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 56ec6927-1593-4131-b290-741ff7e5a3a8
// Created: 2026
// COMPONENT: PrintSheetLayout
// PURPOSE: Calculates safe physical placements and raster dimensions.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PrintSheetLayout -> local result.

import CoreGraphics
import Foundation

/// Calculates safe physical placements and raster dimensions.
struct PrintSheetLayout
{
    /// Bounds a four-byte bitmap to about 320 MB before temporary renderer allocations.
    static let maximumRasterPixelCount = Int64(ImageInputLimits.maximumPixelCount)
    /// Bounds layout allocation before converting calculated counts to integers.
    static let maximumCopyCount = 10_000
    /// The renderer uses four bytes for each raster pixel.
    private static let bytesPerPixel: Int64 = 4
    /// Physical output page width and height in inches.
    let pageSizeInches: CGSize
    /// Physical width and height of each photo copy in inches.
    let photoSizeInches: CGSize
    /// Photo placements measured in inches from the page coordinate origin.
    let photoRectsInches: [CGRect]

    /// Number of whole photo placements in this layout.
    var copyCount: Int
    {
        photoRectsInches.count
    }

    /// Returns whole output pixels for the selected sampling resolution.
    func rasterPixelSize(at resolution: PrintSheetResolution) -> CGSize
    {
        let pixelsPerInch = CGFloat(resolution.rawValue)
        return CGSize(
            width: (pageSizeInches.width * pixelsPerInch).rounded(),
            height: (pageSizeInches.height * pixelsPerInch).rounded()
        )
    }

    /// Estimates four bytes per raster pixel and returns nil when the calculation is unsafe.
    func estimatedRasterBytes(at resolution: PrintSheetResolution) -> Int64?
    {
        let size = rasterPixelSize(at: resolution)
        guard size.width.isFinite, size.height.isFinite,
              size.width > 0, size.height > 0,
              size.width < CGFloat(Int64.max), size.height < CGFloat(Int64.max)
        else
        {
            return nil
        }
        let width = Int64(size.width)
        let height = Int64(size.height)
        guard width > 0, height > 0, width <= Int64.max / height
        else
        {
            return nil
        }
        let pixels = width * height
        guard pixels <= Int64.max / Self.bytesPerPixel
        else
        {
            return nil
        }
        return pixels * Self.bytesPerPixel
    }

    /// Checks the raster budget before a renderer allocates bitmap memory.
    func canRenderRaster(at resolution: PrintSheetResolution) -> Bool
    {
        guard let byteCount = estimatedRasterBytes(at: resolution)
        else
        {
            return false
        }
        return byteCount / Self.bytesPerPixel <= Self.maximumRasterPixelCount
    }

    /// Validates the photo and paper dimensions before computing centered placements.
    static func make(photoSizeInches: CGSize, settings: PrintSheetSettings) throws -> PrintSheetLayout
    {
        try validateInput(photoSizeInches, settings: settings)
        let pageSize = settings.paperSize.orientedSize(for: settings.paperOrientation)
        let grid = try gridCounts(photo: photoSizeInches, page: pageSize, settings: settings)
        let rects = photoPlacements(photo: photoSizeInches, page: pageSize, grid: grid, settings: settings)
        return PrintSheetLayout(pageSizeInches: pageSize, photoSizeInches: photoSizeInches, photoRectsInches: rects)
    }

    /// Rejects invalid measurements before division or conversion to integer grid counts.
    private static func validateInput(_ photo: CGSize, settings: PrintSheetSettings) throws
    {
        guard photo.width.isFinite, photo.height.isFinite, photo.width > 0, photo.height > 0
        else
        {
            throw PrintSheetError.missingPhysicalSize
        }
        guard settings.edgeInsetInches.isFinite, settings.gutterInches.isFinite,
              settings.edgeInsetInches >= 0, settings.gutterInches >= 0
        else
        {
            throw PrintSheetError.photoDoesNotFit
        }
    }

    /// Bounds the grid before allocating positions or converting floating-point counts.
    private static func gridCounts(
        photo: CGSize, page: CGSize, settings: PrintSheetSettings
    ) throws -> (columns: Int, rows: Int)
    {
        let width = page.width - settings.edgeInsetInches * 2
        let height = page.height - settings.edgeInsetInches * 2
        let columns = floor((width + settings.gutterInches) / (photo.width + settings.gutterInches))
        let rows = floor((height + settings.gutterInches) / (photo.height + settings.gutterInches))
        guard columns > 0, rows > 0
        else
        {
            throw PrintSheetError.photoDoesNotFit
        }
        guard columns.isFinite, rows.isFinite, columns <= CGFloat(maximumCopyCount),
              rows <= CGFloat(maximumCopyCount) / columns
        else
        {
            throw PrintSheetError.outputTooLarge
        }
        return (Int(columns), Int(rows))
    }

    /// Centers the complete grid and retains physical inches until a renderer chooses its units.
    private static func photoPlacements(
        photo: CGSize, page: CGSize, grid: (columns: Int, rows: Int), settings: PrintSheetSettings
    ) -> [CGRect]
    {
        let step = CGSize(width: photo.width + settings.gutterInches, height: photo.height + settings.gutterInches)
        let width = CGFloat(grid.columns) * photo.width + CGFloat(grid.columns - 1) * settings.gutterInches
        let height = CGFloat(grid.rows) * photo.height + CGFloat(grid.rows - 1) * settings.gutterInches
        let origin = CGPoint(x: (page.width - width) / 2, y: (page.height - height) / 2)
        var result: [CGRect] = []
        result.reserveCapacity(grid.columns * grid.rows)
        for row in 0 ..< grid.rows
        {
            for column in 0 ..< grid.columns
            {
                let point = CGPoint(
                    x: origin.x + CGFloat(column) * step.width,
                    y: origin.y + CGFloat(row) * step.height
                )
                result.append(CGRect(origin: point, size: photo))
            }
        }
        return result
    }
}
