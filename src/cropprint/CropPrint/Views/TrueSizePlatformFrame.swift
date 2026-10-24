// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 1138a764-1b7f-41ef-8ff2-6e5bb5f4b5fe
// Created: 2026
// COMPONENT: TrueSizePlatformFrame
// PURPOSE: Applies native platform layout for TrueSizePlatformFrame.
// RELATES: [[CropPrint]]
// FLOW: Native application -> TrueSizePlatformFrame -> local result.

import SwiftUI

/// Applies native platform layout for TrueSizePlatformFrame.
struct TrueSizePlatformFrame: ViewModifier
{
    /// Applies the platform-specific frame while preserving native presentation behavior.
    func body(content: Content) -> some View
    {
        #if os(macOS)
        content.frame(minWidth: 640, minHeight: 620)
        #else
        content
        #endif
    }
}
