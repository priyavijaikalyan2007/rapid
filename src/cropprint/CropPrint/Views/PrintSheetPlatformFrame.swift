// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9dca69df-195a-4a16-8acc-381b0f20de6d
// Created: 2026
// COMPONENT: PrintSheetPlatformFrame
// PURPOSE: Applies native platform layout for PrintSheetPlatformFrame.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PrintSheetPlatformFrame -> local result.

import SwiftUI

/// Applies native platform layout for PrintSheetPlatformFrame.
struct PrintSheetPlatformFrame: ViewModifier
{
    /// Applies the platform-specific frame while preserving native presentation behavior.
    func body(content: Content) -> some View
    {
        #if os(macOS)
        content.frame(minWidth: 520, minHeight: 620)
        #else
        content
        #endif
    }
}
