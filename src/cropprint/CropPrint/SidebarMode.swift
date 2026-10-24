// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 841bddb5-11f3-4678-ba3c-6a838b55bacd
// Created: 2026
// COMPONENT: SidebarMode
// PURPOSE: Selects decoration or local photo-adjustment controls in the macOS sidebar.
// RELATES: [[CropPrint]]
// FLOW: Native application -> SidebarMode -> local result.

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Selects decoration or local photo-adjustment controls in the macOS sidebar.
enum SidebarMode: String, CaseIterable, Identifiable
{
    /// Selects decorate within this type's supported choices.
    case decorate
    /// Selects adjust within this type's supported choices.
    case adjust

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
