// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 580144c3-3e5b-4822-96e3-de74a94acaf8
// Created: 2026
// COMPONENT: MobilePhoto
// PURPOSE: Retains upright mobile image pixels and their source dimensions.
// RELATES: [[CropPrint]]
// FLOW: Native application -> MobilePhoto -> local result.

import Photos
import SwiftUI
import UIKit

/// Retains upright mobile image pixels and their source dimensions.
struct MobilePhoto
{
    /// The image value supplied to this MobilePhoto instance.
    let image: UIImage
    /// Decoded local pixels used for crop geometry and export.
    let cgImage: CGImage

    /// Source dimensions in pixels after applying image orientation.
    var pixelSize: CGSize
    {
        CGSize(width: cgImage.width, height: cgImage.height)
    }
}
