// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 85d2e441-15d3-4f09-9acb-b0f9032e711e
// Created: 2026
// COMPONENT: ImageExportError
// PURPOSE: Describes unreadable photos, invalid crops, and image encoding failures.
// RELATES: [[CropPrint]]
// FLOW: Native application -> ImageExportError -> local result.

import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Describes unreadable photos, invalid crops, and image encoding failures.
enum ImageExportError: LocalizedError
{
    /// Represents the unreadable image failure.
    case unreadableImage
    /// Represents the invalid crop failure.
    case invalidCrop
    /// The encoder cannot produce the requested output bytes.
    case encodingFailed

    /// Recovery guidance shown to the user or calling tool.
    var errorDescription: String?
    {
        switch self
        {
        case .unreadableImage: "The app could not read this image. Choose a supported photo file."
        case .invalidCrop: "The crop area is not valid. Reset the crop and try again."
        case .encodingFailed: "The app could not encode the cropped image. Choose a smaller image or a different output preset."
        }
    }
}
