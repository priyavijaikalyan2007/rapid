// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 43939fb3-4849-4093-affa-702de97fe305
// Created: 2026
// COMPONENT: UIImage
// PURPOSE: Renders mobile image orientation into upright pixels before crop geometry.
// RELATES: [[CropPrint]]
// FLOW: Native application -> UIImage -> local result.

import Photos
import SwiftUI
import UIKit

/// Renders mobile image orientation into upright pixels before crop geometry.
extension UIImage
{
    /// Renders image orientation into upright pixels before crop geometry is applied.
    func normalizedForCropping() -> UIImage?
    {
        guard let cgImage
        else
        {
            return nil
        }
        guard imageOrientation != .up
        else
        {
            return self
        }
        let swapsDimensions = imageOrientation == .left || imageOrientation == .leftMirrored
            || imageOrientation == .right || imageOrientation == .rightMirrored
        let outputSize = swapsDimensions
            ? CGSize(width: cgImage.height, height: cgImage.width)
            : CGSize(width: cgImage.width, height: cgImage.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: outputSize, format: format).image
        { _ in
            draw(in: CGRect(origin: .zero, size: outputSize))
        }
    }
}
