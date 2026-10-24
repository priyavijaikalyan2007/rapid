// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 17e75406-33af-4bcf-94c3-0792b0d7d27f
// Created: 2026
// COMPONENT: PhotoProcessingTests
// PURPOSE: Verifies PhotoProcessing contracts and failure boundaries.
// RELATES: [[CropPrint]]
// FLOW: Test scenario -> contract -> XCTest result.

import AppKit
import XCTest

/// Verifies PhotoProcessing contracts and failure boundaries.
final class PhotoProcessingTests: XCTestCase
{
    /// Verifies cancelled processing does not render an image.
    func testCancelledProcessingDoesNotRenderAnImage() async throws
    {
        let source = try solidImage(width: 12, height: 8, color: .white)
        let task = Task.detached
        {
            withUnsafeCurrentTask
            {
                $0?.cancel()
            }
            return try LocalPhotoProcessor.render(
                source: source, settings: PhotoAdjustmentSettings(), cachedPersonMask: nil
            )
        }
        do
        {
            _ = try await task.value
            XCTFail("Cancelled processing must not return an image.")
        }
        catch
        {
            XCTAssertTrue(error is CancellationError)
        }
    }

    /// Verifies default processing preserves dimensions.
    func testDefaultProcessingPreservesDimensions() throws
    {
        let source = try solidImage(width: 120, height: 80, color: .systemBlue)
        let result = try LocalPhotoProcessor.render(
            source: source,
            settings: PhotoAdjustmentSettings(),
            cachedPersonMask: nil
        )

        XCTAssertEqual(result.image.width, 120)
        XCTAssertEqual(result.image.height, 80)
        XCTAssertNil(result.personMask)
    }

    /// Verifies tone and angle processing preserves dimensions.
    func testToneAndAngleProcessingPreservesDimensions() throws
    {
        let source = try solidImage(width: 120, height: 80, color: .systemBlue)
        var settings = PhotoAdjustmentSettings()
        settings.exposure = 0.5
        settings.contrast = 1.2
        settings.highlights = -0.2
        settings.shadows = 0.3
        settings.saturation = 1.1
        settings.hue = 12
        settings.sharpness = 0.4
        settings.angle = 5

        let result = try LocalPhotoProcessor.render(
            source: source,
            settings: settings,
            cachedPersonMask: nil
        )

        XCTAssertEqual(result.image.width, 120)
        XCTAssertEqual(result.image.height, 80)
        let bitmap = NSBitmapImageRep(cgImage: result.image)
        XCTAssertGreaterThan(bitmap.colorAt(x: 0, y: 0)?.alphaComponent ?? 0, 0.99)
        XCTAssertGreaterThan(bitmap.colorAt(x: 119, y: 79)?.alphaComponent ?? 0, 0.99)
    }

    /// Creates a bounded deterministic color fixture without reading personal images.
    private func solidImage(width: Int, height: Int, color: NSColor) throws -> CGImage
    {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: space,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else
        {
            throw PhotoProcessingError.renderFailed
        }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage()
        else
        {
            throw PhotoProcessingError.renderFailed
        }
        return image
    }

    /// Cancelling the caller must cancel the debounce before expensive native processing begins.
    func testProcessingTaskPropagatesCallerCancellation() async throws
    {
        let source = try solidImage(width: 12, height: 8, color: .white)
        let task = Task { try await PhotoProcessingTask.render(
            source: source,
            settings: PhotoAdjustmentSettings(),
            cachedMask: nil
        ) }
        task.cancel()
        do
        {
            _ = try await task.value
            XCTFail("Cancelled edit requests must not publish a preview.")
        }
        catch
        {
            XCTAssertTrue(error is CancellationError)
        }
    }
}
