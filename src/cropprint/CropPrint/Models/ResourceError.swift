// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: e45b09c0-b5a8-47e5-aa02-b7cbd0c4b8f9
// Created: 2026
// COMPONENT: ResourceError
// PURPOSE: Describes catalog validation failures and the action needed to recover.
// RELATES: [[CropPrint]]
// FLOW: Native application -> ResourceError -> local result.

import Foundation

/// Describes catalog validation failures and the action needed to recover.
enum ResourceError: LocalizedError
{
    /// Represents the unsupported catalog failure.
    case unsupportedCatalog
    /// Represents the empty catalog failure.
    case emptyCatalog
    /// Represents the duplicate identifier failure.
    case duplicateIdentifier
    /// Represents the disallowed license failure.
    case disallowedLicense
    /// Represents the missing attribution failure.
    case missingAttribution
    /// Represents the invalid identifier failure.
    case invalidIdentifier
    /// Represents the unsupported file failure.
    case unsupportedFile
    /// Represents the missing font name failure.
    case missingFontName

    /// Recovery guidance shown to the user or calling tool.
    var errorDescription: String?
    {
        switch self
        {
        case .unsupportedCatalog: "The catalog version is not supported. Choose a version 1 catalog."
        case .emptyCatalog: "The catalog contains no resources. Check the catalog or use the built-in list."
        case .duplicateIdentifier: "The catalog contains duplicate identifiers. Check that each entry has a unique identifier."
        case .disallowedLicense: "The resource license is not allowed. Choose a resource with a supported license."
        case .missingAttribution: "The resource attribution is incomplete or too long. Check the creator, name, and metadata lengths."
        case .invalidIdentifier: "The resource identifier is unsafe. Check its length and use only supported filename characters."
        case .unsupportedFile: "The resource file type is not supported. Choose a supported font or image file."
        case .missingFontName: "A font entry does not contain its PostScript font name. Check the catalog entry."
        }
    }
}
