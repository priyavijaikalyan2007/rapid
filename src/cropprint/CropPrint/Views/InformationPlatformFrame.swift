// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: bb283a9c-71a4-4fb6-aa52-15d3ad7c6111
// Created: 2026
// COMPONENT: InformationPlatformFrame
// PURPOSE: Applies native platform layout for InformationPlatformFrame.
// RELATES: [[CropPrint]]
// FLOW: Native application -> InformationPlatformFrame -> local result.

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Applies native platform layout for InformationPlatformFrame.
struct InformationPlatformFrame: ViewModifier
{
    /// The min width value supplied to this InformationPlatformFrame instance.
    let minWidth: CGFloat
    /// The min height value supplied to this InformationPlatformFrame instance.
    let minHeight: CGFloat

    /// Applies the platform-specific frame while preserving native presentation behavior.
    func body(content: Content) -> some View
    {
        #if os(macOS)
        content.frame(minWidth: minWidth, minHeight: minHeight)
        #else
        content
        #endif
    }
}
