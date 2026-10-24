// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 0d5bbd28-3e71-4cfa-8686-4667d6db602c
// Created: 2026
// COMPONENT: PhotoAdjustmentSettings
// PURPOSE: Stores neutral and edited tone, rotation, and background values in memory.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PhotoAdjustmentSettings -> local result.

import CoreGraphics
import Foundation

/// Stores neutral and edited tone, rotation, and background values in memory.
struct PhotoAdjustmentSettings: Equatable
{
    /// Exposure compensation in stops, from -2 through 2 in the editor.
    var exposure: Double = 0
    /// Contrast multiplier from 0.5 through 1.5, with one as the neutral value.
    var contrast: Double = 1
    /// Highlight adjustment from -1 through 1, with zero as the neutral value.
    var highlights: Double = 0
    /// Shadow adjustment from -1 through 1, with zero as the neutral value.
    var shadows: Double = 0
    /// Saturation multiplier from zero through two, with one as the neutral value.
    var saturation: Double = 1
    /// Hue rotation in degrees from -180 through 180.
    var hue: Double = 0
    /// Local luminance sharpening from zero through one.
    var sharpness: Double = 0
    /// Straightening angle in degrees from -15 through 15.
    var angle: Double = 0
    /// Optional solid replacement behind the on-device person mask.
    var background: ReplacementBackground = .original

    /// Indicates that all controls match the source-preserving neutral settings.
    var isDefault: Bool
    {
        self == PhotoAdjustmentSettings()
    }

    /// Indicates changes to tone, detail, or angle independently of background replacement.
    var hasToneChanges: Bool
    {
        exposure != 0 || contrast != 1 || highlights != 0 || shadows != 0
            || saturation != 1 || hue != 0 || sharpness != 0 || angle != 0
    }
}
