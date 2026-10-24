// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 2c7e5755-a426-489d-bc23-7af669ef1dc2
// Created: 2026
// COMPONENT: Photo transfer boundary tests
// PURPOSE: Reject oversized picker files before buffering their compressed bytes.
// RELATES: ImportedPhoto, ImageInputLimits
// FLOW: Sparse oversized file -> metadata validation -> rejection without loading its body.

import AppKit
import Foundation
import XCTest

/// Checks the file-transfer boundary independently of the system photo picker.
final class ImportedPhotoTests: XCTestCase
{
    /// Uses a sparse file so the test does not allocate a 200 MB input buffer.
    func testOversizedTransferIsRejectedFromFileMetadata() throws
    {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: nil))
        defer { try? FileManager.default.removeItem(at: url) }
        let handle = try FileHandle(forWritingTo: url)
        try handle.truncate(atOffset: UInt64(ImageInputLimits.maximumFileBytes) + 1)
        try handle.close()
        XCTAssertThrowsError(try ImportedPhoto(contentsOf: url))
        { error in
            XCTAssertEqual(error as? ImageInputLimits.Failure, .imageTooLarge)
        }
    }

    /// Keeps a valid transferred file byte-for-byte intact after bounded reading.
    func testValidTransferPreservesCompressedBytes() throws
    {
        let context = try XCTUnwrap(BitmapCanvas.make(size: CGSize(width: 4, height: 3)))
        let image = try XCTUnwrap(context.makeImage())
        let original = try XCTUnwrap(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try original.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertEqual(try ImportedPhoto(contentsOf: url).data, original)
    }
}
