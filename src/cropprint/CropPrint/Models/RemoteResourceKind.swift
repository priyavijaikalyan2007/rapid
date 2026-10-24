// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 05b1cf32-910a-48d2-a969-60982b67443c
// Created: 2026
// COMPONENT: RemoteResourceKind
// PURPOSE: Distinguishes font files from image frames in resource catalogs.
// RELATES: [[CropPrint]]
// FLOW: Native application -> RemoteResourceKind -> local result.

import Foundation

/// Distinguishes font files from image frames in resource catalogs.
enum RemoteResourceKind: String, Codable, CaseIterable
{
    /// Selects font within this type's supported choices.
    case font
    /// Selects frame within this type's supported choices.
    case frame

    /// User-facing label displayed by the native selection controls.
    var title: String
    {
        switch self
        {
        case .font: "Font"
        case .frame: "Frame"
        }
    }
}
