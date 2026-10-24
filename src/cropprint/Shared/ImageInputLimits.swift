// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b039ccac-d639-4a29-a797-ec08f8232749
// Created: 2026
// COMPONENT: ImageInputLimits
// PURPOSE: Rejects oversized compressed files and unsafe dimensions before native image decoding.
// RELATES: [[CropPrint]]
// FLOW: Native application -> ImageInputLimits -> local result.

import CoreGraphics
import Foundation
import ImageIO

/// Checks compressed input and image metadata before the application decodes a full raster.
enum ImageInputLimits
{
    /// Matches the existing print-sheet raster budget of 80 million pixels.
    static let maximumPixelCount = 80_000_000
    /// Bounds compressed photo data accepted by the application.
    static let maximumFileBytes = 200_000_000

    /// Errors describe only the image-input validation contract.
    enum Failure: LocalizedError
    {
        case unreadableImage
        case imageTooLarge

        var errorDescription: String?
        {
            switch self
            {
            case .unreadableImage:
                "The app cannot read this image. Choose a supported photo file."
            case .imageTooLarge:
                "The image exceeds the safe size limit. Choose a file below 200 MB and 80 million pixels."
            }
        }
    }

    /// Validates positive finite dimensions without an overflowing pixel-count multiplication.
    static func validate(width: CGFloat, height: CGFloat) throws
    {
        guard width.isFinite, height.isFinite, width > 0, height > 0,
              width <= CGFloat(maximumPixelCount) / height
        else
        {
            throw Failure.imageTooLarge
        }
    }

    /// Inspects in-memory compressed data without caching a decoded bitmap.
    static func validate(data: Data) throws
    {
        guard data.count <= maximumFileBytes
        else
        {
            throw Failure.imageTooLarge
        }
        guard let source = CGImageSourceCreateWithData(
            data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary
        ) else
        {
            throw Failure.unreadableImage
        }
        try validate(source: source)
    }

    /// Checks the selected file's byte count and first image dimensions before loading it.
    static func validate(url: URL) throws
    {
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true, let size = values.fileSize
        else
        {
            throw Failure.unreadableImage
        }
        guard size <= maximumFileBytes
        else
        {
            throw Failure.imageTooLarge
        }
        guard let source = CGImageSourceCreateWithURL(
            url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary
        ) else
        {
            throw Failure.unreadableImage
        }
        try validate(source: source)
    }

    /// Uses ImageIO metadata so pixel limits apply before an AppKit or UIKit decode.
    private static func validate(source: CGImageSource) throws
    {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight] as? NSNumber
        else
        {
            throw Failure.unreadableImage
        }
        try validate(width: CGFloat(width.doubleValue), height: CGFloat(height.doubleValue))
    }
}
