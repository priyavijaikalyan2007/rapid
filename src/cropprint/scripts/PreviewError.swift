// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: dc0ac97d-babf-4993-9af4-744350dda8be
// Created: 2026
// COMPONENT: PreviewError
// PURPOSE: Defines the PreviewError domain values and their contracts.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PreviewError -> local result.

import AVFoundation
import CoreImage
import Foundation

/// Defines the PreviewError domain values and their contracts.
/// Recoverable failures in preview argument validation or media export setup.
enum PreviewError: LocalizedError
{
    /// Represents the invalid arguments failure.
    case invalidArguments
    /// Represents the existing destination failure.
    case existingDestination
    /// Represents the missing video track failure.
    case missingVideoTrack
    /// Represents the cannot create exporter failure.
    case cannotCreateExporter

    /// Recovery guidance shown to the user or calling tool.
    var errorDescription: String?
    {
        switch self
        {
        case .invalidArguments: "Use: normalize SOURCE OUTPUT WIDTH HEIGHT. Each dimension must be from 1 through 7680 pixels."
        case .existingDestination: "The output already exists or matches the source. Choose a new output path."
        case .missingVideoTrack: "The source has no readable video track. Choose a supported video file."
        case .cannotCreateExporter: "The system cannot export this video. Check its format and try again."
        }
    }
}
