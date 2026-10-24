// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 6ef73449-6ad2-424b-bef4-7adf2fcec436
// Created: 2026
// COMPONENT: CropPrintMobileApp
// PURPOSE: Composes the native mobile application and shared resource state.
// RELATES: [[CropPrint]]
// FLOW: Native application -> CropPrintMobileApp -> local result.

import SwiftUI

/// Composes the native mobile application and shared resource state.
@main
struct CropPrintMobileApp: App
{
    /// Resource library used by CropPrintMobileApp.
    @StateObject private var resourceLibrary = ResourceLibrary.shared

    /// Native scene or view content derived from the current application state.
    var body: some Scene
    {
        WindowGroup
        {
            MobileContentView()
                .environmentObject(resourceLibrary)
        }
    }
}
