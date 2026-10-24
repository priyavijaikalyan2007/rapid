// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c127a467-03e3-428b-8ef5-eed7671e0c99
// Created: 2026
// COMPONENT: Resource catalog validation
// PURPOSE: Bound untrusted catalog fields before cache and native parser access.
// RELATES: ResourceLibrary, PhotoDocument, MobilePhotoDocument
// FLOW: Validated input -> bounded local work -> recoverable result.

import Foundation

/// Validates licensed resource metadata independently of transport and UI state.
enum ResourceCatalogPolicy
{
    /// Bounds the number of cached-resource choices exposed by a remote catalog.
    static let maximumEntries = 250
    /// Bounds human-readable metadata without truncating the required attribution.
    private static let maximumTextLength = 2_000
    /// Restricts cache file names to a portable length.
    private static let maximumIdentifierLength = 128
    /// Licenses accepted by the existing optional resource contract.
    private static let allowedLicenses = [
        "OFL-1.1",
        "Apache-2.0",
        "Ubuntu-font-1.0",
        "CC0-1.0",
        "CC-BY-4.0",
        "CC-BY-SA-4.0",
        "MIT"
    ]
    /// Rejects unsupported or unsafe values before downstream processing or storage.
    static func validate(_ catalog: RemoteResourceCatalog) throws
    {
        guard catalog.version == 1
        else
        {
            throw ResourceError.unsupportedCatalog
        }
        guard !catalog.resources.isEmpty, catalog.resources.count <= maximumEntries
        else
        {
            throw ResourceError.emptyCatalog
        }
        guard Set(catalog.resources.map(\.id)).count == catalog.resources.count
        else
        {
            throw ResourceError.duplicateIdentifier
        }
        try catalog.resources.forEach
        {
            try validate($0)
        }
    }

    /// Validates all metadata before using a resource as a cache key or native file.
    static func validate(_ resource: RemoteResource) throws
    {
        guard allowedLicenses.contains(resource.licenseName)
        else
        {
            throw ResourceError.disallowedLicense
        }
        try validateAttribution(resource)
        for address in [resource.sourceURL, resource.downloadURL, resource.licenseURL]
        {
            try ResourceDownloadPolicy.validateAddress(address)
        }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-_.")
        guard !resource.id.isEmpty, resource.id.count <= maximumIdentifierLength,
              resource.id.first?.isLetter == true || resource.id.first?.isNumber == true,
              resource.id.unicodeScalars.allSatisfy(allowed.contains)
        else
        {
            throw ResourceError.invalidIdentifier
        }
        try validateExtension(resource)
        if resource.kind == .font, resource.fontName?.isEmpty != false
        {
            throw ResourceError.missingFontName
        }
    }

    /// Rejects missing or oversized attribution instead of displaying incomplete license information.
    private static func validateAttribution(_ resource: RemoteResource) throws
    {
        guard !resource.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !resource.creator.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              [resource.name, resource.creator, resource.notes ?? "", resource.fontName ?? ""]
                  .allSatisfy({
                      $0.count <= maximumTextLength
                  })
        else
        {
            throw ResourceError.missingAttribution
        }
    }

    /// Confines native parsers to the existing supported font and image file types.
    private static func validateExtension(_ resource: RemoteResource) throws
    {
        let extensions = resource.kind == .font ? ["ttf", "otf"] : ["png", "jpg", "jpeg", "heic", "tiff"]
        guard extensions.contains(resource.downloadURL.pathExtension.lowercased())
        else
        {
            throw ResourceError.unsupportedFile
        }
    }
}
