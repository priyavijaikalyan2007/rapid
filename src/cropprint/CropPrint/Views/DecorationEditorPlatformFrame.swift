// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 777bfab7-a0a8-43ad-9711-fc1a1238cc14
// Created: 2026
// COMPONENT: DecorationEditorPlatformFrame
// PURPOSE: Applies native platform layout for DecorationEditorPlatformFrame.
// RELATES: [[CropPrint]]
// FLOW: Native application -> DecorationEditorPlatformFrame -> local result.

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Applies native platform layout for DecorationEditorPlatformFrame.
struct DecorationEditorPlatformFrame: ViewModifier
{
    /// The shows done button value supplied to this DecorationEditorPlatformFrame instance.
    let showsDoneButton: Bool

    /// Applies the platform-specific frame while preserving native presentation behavior.
    func body(content: Content) -> some View
    {
        #if os(macOS)
        content.frame(
            minWidth: showsDoneButton ? 520 : 280,
            minHeight: 620
        )
        #else
        content.frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}
