// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 576497fd-00d6-4cdb-8dad-e41d74df9c8b
// Created: 2026
// COMPONENT: InformationPage
// PURPOSE: Selects one native information or editor sheet in the mobile application.
// RELATES: [[CropPrint]]
// FLOW: Native application -> InformationPage -> local result.

import PhotosUI
import SwiftUI

/// Selects one native information or editor sheet in the mobile application.
enum InformationPage: String, Identifiable
{
    /// Selects about within this type's supported choices.
    case about
    /// Selects attributions within this type's supported choices.
    case attributions
    /// Selects resources within this type's supported choices.
    case resources
    /// Selects help within this type's supported choices.
    case help
    /// Selects decorate within this type's supported choices.
    case decorate
    /// Selects adjust within this type's supported choices.
    case adjust

    /// Identity used by native selection controls.
    var id: String
    {
        rawValue
    }
}
