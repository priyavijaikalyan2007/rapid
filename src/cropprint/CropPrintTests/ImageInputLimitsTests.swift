// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: ac0433b8-5ee4-4a54-82e7-ec60ca1855dd
// Created: 2026
// COMPONENT: ImageInputLimitsTests
// PURPOSE: Verifies ImageInputLimits contracts and failure boundaries.
// RELATES: [[CropPrint]]
// FLOW: Test scenario -> contract -> XCTest result.

import AppKit
import CoreGraphics
import XCTest

/// Verifies ImageInputLimits contracts and failure boundaries.
final class ImageInputLimitsTests: XCTestCase
{
    /// Verifies oversized dimensions are rejected before decoding.
    func testOversizedDimensionsAreRejectedBeforeDecoding()
    {
        XCTAssertThrowsError(try ImageInputLimits.validate(width: 100_000, height: 100_000))
    }

    /// Verifies azero dimension is rejected.
    func testAZeroDimensionIsRejected()
    {
        XCTAssertThrowsError(try ImageInputLimits.validate(width: 0, height: 100))
    }

    /// Verifies an infinite dimension is rejected.
    func testAnInfiniteDimensionIsRejected()
    {
        XCTAssertThrowsError(try ImageInputLimits.validate(width: .infinity, height: 100))
    }

    /// Verifies typical camera dimensions are accepted.
    func testTypicalCameraDimensionsAreAccepted()
    {
        XCTAssertNoThrow(try ImageInputLimits.validate(width: 8000, height: 6000))
    }

    /// Rejects corrupt compressed input without decoding a full bitmap.
    func testCorruptImageDataIsRejected()
    {
        XCTAssertThrowsError(try ImageInputLimits.validate(data: Data("invalid image".utf8)))
    }

    /// Applies input bounds to real ImageIO metadata as well as direct dimension checks.
    func testValidEncodedImageMetadataIsAccepted() throws
    {
        let context = try XCTUnwrap(BitmapCanvas.make(size: CGSize(width: 4, height: 3)))
        let image = try XCTUnwrap(context.makeImage())
        let data = try XCTUnwrap(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        XCTAssertNoThrow(try ImageInputLimits.validate(data: data))
    }
}
