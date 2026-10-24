// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: acf6a80c-6832-41ed-aeca-a89020c09b2e
// Created: 2026
// COMPONENT: PhotoProcessingError
// PURPOSE: Describes local segmentation and rendering failures with recovery actions.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PhotoProcessingError -> local result.

import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import Vision

/// Describes local segmentation and rendering failures with recovery actions.
enum PhotoProcessingError: LocalizedError
{
    /// Represents the no person found failure.
    case noPersonFound
    /// The native renderer cannot create an output image.
    case renderFailed

    /// Recovery guidance shown to the user or calling tool.
    var errorDescription: String?
    {
        switch self
        {
        case .noPersonFound:
            """
            The app could not find a person to separate from the background. Choose a clearer portrait or keep the \
            original background.
            """
        case .renderFailed:
            "The app could not apply the photo edits. Reset the edits or choose a smaller image."
        }
    }
}
