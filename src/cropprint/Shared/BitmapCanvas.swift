// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: bb355253-42cf-47a7-999f-9c3496dc7b68
// Created: 2026
// COMPONENT: Bounded bitmap canvas
// PURPOSE: Allocate shared raster contexts only after validating finite pixel dimensions.
// RELATES: ImageInputLimits, ImageExporter, DecorationRenderer, PrintSheetRenderer
// FLOW: Requested pixel size -> validation -> sRGB context or allocation failure.

import CoreGraphics
import Foundation

/// Creates bounded eight-bit sRGB contexts for the native rendering services.
enum BitmapCanvas
{
    /// Uses one byte per color component in the existing renderer format.
    private static let bitsPerComponent = 8

    /// Returns nil for unsafe sizes or allocation failures without an overflowing integer conversion.
    static func make(
        size: CGSize, alpha: CGImageAlphaInfo = .premultipliedLast
    ) -> CGContext?
    {
        let width = size.width.rounded()
        let height = size.height.rounded()
        do
        {
            try ImageInputLimits.validate(width: width, height: height)
        }
        catch
        {
            return nil
        }
        guard let space = CGColorSpace(name: CGColorSpace.sRGB)
        else
        {
            return nil
        }
        return CGContext(
            data: nil, width: Int(width), height: Int(height), bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0, space: space, bitmapInfo: alpha.rawValue
        )
    }
}
