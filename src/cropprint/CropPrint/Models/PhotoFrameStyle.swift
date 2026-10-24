// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c45e4947-3aec-4635-9c6e-e161aecb4439
// Created: 2026
// COMPONENT: PhotoFrameStyle
// PURPOSE: Selects the supported built-in photo border shapes.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PhotoFrameStyle -> local result.

import SwiftUI

/// Selects the supported built-in photo border shapes.
enum PhotoFrameStyle: String, CaseIterable, Identifiable
{
    /// Selects none within this type's supported choices.
    case none = "None"
    /// Selects classic within this type's supported choices.
    case classic = "Classic"
    /// Selects double within this type's supported choices.
    case double = "Double"
    /// Selects rounded within this type's supported choices.
    case rounded = "Rounded"
    /// Selects film within this type's supported choices.
    case film = "Film"
    /// Selects polaroid within this type's supported choices.
    case polaroid = "Polaroid"

    /// Identity used by native selection controls.
    var id: Self
    {
        self
    }
}
