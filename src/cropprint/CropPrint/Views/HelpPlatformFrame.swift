// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: e9024224-0ff1-48c4-9286-5367af014d6e
// Created: 2026
// COMPONENT: HelpPlatformFrame
// PURPOSE: Applies native platform layout for HelpPlatformFrame.
// RELATES: [[CropPrint]]
// FLOW: Native application -> HelpPlatformFrame -> local result.

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Applies native platform layout for HelpPlatformFrame.
struct HelpPlatformFrame: ViewModifier
{
    /// Applies the platform-specific frame while preserving native presentation behavior.
    func body(content: Content) -> some View
    {
        #if os(macOS)
        content.frame(minWidth: 650, minHeight: 620)
        #else
        content
        #endif
    }
}
