// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 35c69bd5-398d-4462-adb0-b9b911f0e08b
// Created: 2026
// COMPONENT: CropCorner
// PURPOSE: Adds CropCanvas behavior to CropCorner.
// RELATES: [[CropPrint]]
// FLOW: Native application -> CropCorner -> local result.

import SwiftUI

/// Adds CropCanvas behavior to CropCorner.
extension CropCorner
{
    /// Accessibility name used by CropCorner.
    var accessibilityName: String
    {
        switch self
        {
        case .topLeft: "top left"
        case .topRight: "top right"
        case .bottomLeft: "bottom left"
        case .bottomRight: "bottom right"
        }
    }
}
