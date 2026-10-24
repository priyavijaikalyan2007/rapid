// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File 73f1dc58-0c63-4d1d-a54f-706aa8ff152e: 73f1dc58-0c63-4d1d-a54f-706aa8ff152e
// Created: 2026
// COMPONENT: Preview command boundary tests
// PURPOSE: Preserve source media and reject unsafe render sizes before opening AVFoundation.
// RELATES: PreviewExportRequest, PreviewNormalizer
// FLOW: Command arguments -> validation -> usable export request or error.

import Foundation
import XCTest

/// Tests media command boundaries without exporting or replacing any tracked asset.
final class PreviewExportRequestTests: XCTestCase
{
    /// Rejects identical source and destination paths before media access.
    func testSameSourceAndDestination() throws
    {
        XCTAssertThrowsError(try PreviewExportRequest([
            "normalize",
            "/tmp/source.mp4",
            "/tmp/source.mp4",
            "1920",
            "1080"
        ]))
    }

    /// Bounds user-supplied dimensions before allocating video buffers.
    func testUnsafeDimensions() throws
    {
        for size in ["0", "-1", "999999999999999999999999", "100000", "NaN"]
        {
            XCTAssertThrowsError(try PreviewExportRequest([
                "normalize",
                "/tmp/source.mp4",
                "/tmp/dest.mp4",
                size,
                "1080"
            ]))
        }
    }

    /// Preserves a completed export instead of deleting it before a replacement succeeds.
    func testExistingDestinationIsPreserved() throws
    {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let destination = folder.appendingPathComponent("existing.mp4")
        let original = Data("completed export".utf8)
        try original.write(to: destination)
        XCTAssertThrowsError(try PreviewExportRequest([
            "normalize",
            folder.appendingPathComponent("source.mp4").path,
            destination.path,
            "1920",
            "1080"
        ]))
        XCTAssertEqual(try Data(contentsOf: destination), original)
    }
}
