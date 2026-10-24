// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: fb389c06-919b-4ac2-bf1c-a7ce060f07b7
// Created: 2026
// COMPONENT: PrintSheetError
// PURPOSE: Describes invalid physical layouts and failed sheet rendering or encoding.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PrintSheetError -> local result.

import CoreGraphics
import Foundation

/// Describes invalid physical layouts and failed sheet rendering or encoding.
enum PrintSheetError: LocalizedError
{
    /// Represents the missing physical size failure.
    case missingPhysicalSize
    /// Represents the photo does not fit failure.
    case photoDoesNotFit
    /// Represents the output too large failure.
    case outputTooLarge
    /// The native renderer cannot create an output image.
    case renderingFailed
    /// The encoder cannot produce the requested output bytes.
    case encodingFailed

    /// Recovery guidance shown to the user or calling tool.
    var errorDescription: String?
    {
        switch self
        {
        case .missingPhysicalSize:
            "Select a print or physical passport size before creating a print sheet."
        case .photoDoesNotFit:
            "The selected photo size does not fit on this paper. Choose larger paper or a smaller photo size."
        case .outputTooLarge:
            """
            This paper and image PPI combination exceeds the safe raster limit. Choose lower image PPI or smaller \
            paper.
            """
        case .renderingFailed:
            "The app could not render the print sheet. Choose lower image PPI or smaller paper."
        case .encodingFailed:
            "The app could not encode the print sheet. Choose a smaller sheet or try again."
        }
    }
}
