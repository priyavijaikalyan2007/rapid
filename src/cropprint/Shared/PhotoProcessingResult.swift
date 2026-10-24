// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 25c1b43e-cbd1-4e0f-a608-10c0a8d455b8
// Created: 2026
// COMPONENT: PhotoProcessingResult
// PURPOSE: Carries locally processed image pixels and an optional reusable person mask.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PhotoProcessingResult -> local result.

import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import Vision

/// Carries locally processed image pixels and an optional reusable person mask.
struct PhotoProcessingResult
{
    /// Pixels after local tone, rotation, and background processing.
    let image: CGImage
    /// Reusable on-device foreground mask for the currently loaded photo.
    let personMask: CGImage?
}
