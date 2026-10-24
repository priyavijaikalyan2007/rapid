// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4d52f5f5-bd41-4a2d-beed-59dd9c00fffd
// Created: 2026
// COMPONENT: MobilePhotoError
// PURPOSE: Describes mobile input, rendering, and Photos permission failures.
// RELATES: [[CropPrint]]
// FLOW: Native application -> MobilePhotoError -> local result.

import Foundation

/// Describes mobile input, rendering, and Photos permission failures.
enum MobilePhotoError: LocalizedError
{
    /// Represents the unreadable image failure.
    case unreadableImage
    /// Represents the invalid crop failure.
    case invalidCrop
    /// The native renderer cannot create an output image.
    case renderFailed
    /// Represents the photos access denied failure.
    case photosAccessDenied

    /// Recovery guidance shown to the user or calling tool.
    var errorDescription: String?
    {
        switch self
        {
        case .unreadableImage: "The app could not read this image. Choose a supported photo file."
        case .invalidCrop: "The crop area is not valid. Reset the crop and try again."
        case .renderFailed: "The app could not create the cropped image. Choose a smaller image or reset the edits."
        case .photosAccessDenied: "Allow CropPrint to add photos in Settings."
        }
    }
}
