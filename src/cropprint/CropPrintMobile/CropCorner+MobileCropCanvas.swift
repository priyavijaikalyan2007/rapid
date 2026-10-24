// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 0a923543-e730-4b5f-86f9-1730b70b8f6e
// Created: 2026
// COMPONENT: CropCorner
// PURPOSE: Adds MobileCropCanvas behavior to CropCorner.
// RELATES: [[CropPrint]]
// FLOW: Native application -> CropCorner -> local result.

import SwiftUI

/// Adds MobileCropCanvas behavior to CropCorner.
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
