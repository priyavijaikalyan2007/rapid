// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 6aff2da1-11f0-48aa-ad5b-0f0f301518d5
// Created: 2026
// COMPONENT: Bounded photo transfer
// PURPOSE: Inspect picker file metadata before buffering a bounded compressed image.
// RELATES: MobileContentView, ImageInputLimits, ImportedPhotoTests
// FLOW: System photo picker -> temporary file -> metadata and byte limits -> local photo document.
// SECURITY: Read file data only inside the transfer lifetime and never exceed the compressed-input budget.

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// Receives system photo-picker files without requesting an unbounded Data representation.
struct ImportedPhoto: Transferable
{
    /// Bounds each temporary read while preserving a fixed total input budget.
    private static let readChunkBytes = 65_536
    /// Compressed image bytes retained only until the document decodes the selected photo.
    let data: Data

    /// Checks metadata before reading, then validates the actual bounded bytes against replacement races.
    init(contentsOf url: URL) throws
    {
        try ImageInputLimits.validate(url: url)
        data = try Self.readBoundedData(from: url)
        try ImageInputLimits.validate(data: data)
    }

    /// Consumes the temporary file while CoreTransferable guarantees its access lifetime.
    static var transferRepresentation: some TransferRepresentation
    {
        FileRepresentation(importedContentType: .image)
        { received in
            try ImportedPhoto(contentsOf: received.file)
        }
    }

    /// Enforces the byte cap during reading even if a file changes after the initial metadata check.
    private static func readBoundedData(from url: URL) throws -> Data
    {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var result = Data()
        while let chunk = try handle.read(upToCount: readChunkBytes), !chunk.isEmpty
        {
            try Task.checkCancellation()
            guard chunk.count <= ImageInputLimits.maximumFileBytes - result.count
            else
            {
                throw ImageInputLimits.Failure.imageTooLarge
            }
            result.append(chunk)
        }
        try Task.checkCancellation()
        return result
    }
}
