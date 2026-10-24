// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 8c8de0cc-8ea0-4272-a7ac-e0162bd9755a
// Created: 2026
// COMPONENT: PresetCategory
// PURPOSE: Groups crop presets into the categories shown by the native editors.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PresetCategory -> local result.

import CoreGraphics
import Foundation

/// Groups crop presets into the categories shown by the native editors.
enum PresetCategory: String, CaseIterable, Identifiable
{
    /// Selects print within this type's supported choices.
    case print = "Print"
    /// Selects passport within this type's supported choices.
    case passport = "Passport and ID"
    /// Selects instagram within this type's supported choices.
    case instagram = "Instagram"
    /// Selects i phone within this type's supported choices.
    case iPhone = "iPhone wallpaper"
    /// Selects mac book within this type's supported choices.
    case macBook = "MacBook wallpaper"
    /// Selects monitor within this type's supported choices.
    case monitor = "Monitor wallpaper"

    /// Identity used by native selection controls.
    var id: Self
    {
        self
    }

    /// Presets used by PresetCategory.
    var presets: [CropPreset]
    {
        CropPreset.allCases.filter
        {
            $0.category == self
        }
    }
}
