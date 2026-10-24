// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 0532ad11-3e6b-4a33-b43e-87e74480985e
// Created: 2026
// COMPONENT: TextDecorationStyle
// PURPOSE: Selects plain, outlined, shadowed, or badge text rendering.
// RELATES: [[CropPrint]]
// FLOW: Native application -> TextDecorationStyle -> local result.

import SwiftUI

/// Selects plain, outlined, shadowed, or badge text rendering.
enum TextDecorationStyle: String, CaseIterable, Identifiable
{
    /// Selects clean within this type's supported choices.
    case clean = "Clean"
    /// Selects shadow within this type's supported choices.
    case shadow = "Shadow"
    /// Selects outline within this type's supported choices.
    case outline = "Outline"
    /// Selects badge within this type's supported choices.
    case badge = "Badge"

    /// Identity used by native selection controls.
    var id: Self
    {
        self
    }
}
