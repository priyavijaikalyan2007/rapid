// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: dd4caa33-8b89-4365-8cde-8815f885572b
// Created: 2026
// COMPONENT: LoadedPhoto
// PURPOSE: Loads a selected macOS photo after metadata and size checks.
// RELATES: [[CropPrint]]
// FLOW: Native application -> LoadedPhoto -> local result.

import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Loads a selected macOS photo after metadata and size checks.
struct LoadedPhoto
{
    /// The image value supplied to this LoadedPhoto instance.
    let image: NSImage
    /// Decoded local pixels used for crop geometry and export.
    let cgImage: CGImage
    /// Source location retained for local access or visible attribution.
    let sourceURL: URL

    /// Source dimensions in pixels after applying image orientation.
    var pixelSize: CGSize
    {
        CGSize(width: cgImage.width, height: cgImage.height)
    }

    /// Validates and decodes one selected file without changing its contents.
    init(url: URL) throws
    {
        try ImageInputLimits.validate(url: url)
        guard let image = NSImage(contentsOf: url)
        else
        {
            throw ImageExportError.unreadableImage
        }

        var proposedRect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
        else
        {
            throw ImageExportError.unreadableImage
        }

        self.image = image
        self.cgImage = cgImage
        self.sourceURL = url
    }
}
