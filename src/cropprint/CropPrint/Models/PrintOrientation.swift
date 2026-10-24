// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: caa53c60-43d1-415b-a2f9-87a00cc56ea1
// Created: 2026
// COMPONENT: PrintOrientation
// PURPOSE: Selects portrait or landscape dimensions for presets that support rotation.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PrintOrientation -> local result.

import CoreGraphics
import Foundation

/// Selects portrait or landscape dimensions for presets that support rotation.
enum PrintOrientation: String, CaseIterable, Identifiable
{
    /// Selects portrait within this type's supported choices.
    case portrait
    /// Selects landscape within this type's supported choices.
    case landscape

    /// Identity used by native selection controls.
    var id: Self
    {
        self
    }

    /// User-facing label displayed by the native selection controls.
    var title: String
    {
        rawValue.capitalized
    }
}
