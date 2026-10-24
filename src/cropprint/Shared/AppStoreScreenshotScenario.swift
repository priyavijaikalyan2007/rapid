// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: fd3f0f0e-ee3b-4e86-8897-2d96f1a3f094
// Created: 2026
// COMPONENT: AppStoreScreenshotScenario
// PURPOSE: Selects fixed debug-only samples and presentation states for App Store media.
// RELATES: [[CropPrint]]
// FLOW: Native application -> AppStoreScreenshotScenario -> local result.

import Foundation

/// Selects fixed debug-only samples and presentation states for App Store media.
enum AppStoreScreenshotScenario: String
{
    /// Selects crop within this type's supported choices.
    case crop
    /// Selects decorate within this type's supported choices.
    case decorate
    /// Selects passport within this type's supported choices.
    case passport
    /// Selects print sheet within this type's supported choices.
    case printSheet = "print-sheet"
    /// Selects true size within this type's supported choices.
    case trueSize = "true-size"
    /// Selects resources within this type's supported choices.
    case resources
    /// Selects preview within this type's supported choices.
    case preview

    /// Current used by AppStoreScreenshotScenario.
    static var current: AppStoreScreenshotScenario?
    {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let optionIndex = arguments.firstIndex(of: "--app-store-screenshot"),
              arguments.indices.contains(optionIndex + 1)
        else
        {
            return nil
        }
        return AppStoreScreenshotScenario(rawValue: arguments[optionIndex + 1])
        #else
        return nil
        #endif
    }

    /// Sample photo url used by AppStoreScreenshotScenario.
    static var samplePhotoURL: URL?
    {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let optionIndex = arguments.firstIndex(of: "--screenshot-photo"),
           arguments.indices.contains(optionIndex + 1)
        {
            return URL(fileURLWithPath: arguments[optionIndex + 1])
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("CropPrint-Screenshot-Sample.png")
        #else
        nil
        #endif
    }
}
