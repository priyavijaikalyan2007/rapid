// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 5dff0301-a20a-4e9f-95de-986dc4fb5554
// Created: 2026
// COMPONENT: Native domain contracts
// PURPOSE: Check local preview completion, palette consistency, edit state, and actionable errors.
// RELATES: PhotoProcessingTask, DecorationColor, PhotoAdjustmentSettings
// FLOW: Synthetic input -> native domain value -> observable contract.

import AppKit
import XCTest

/// Covers shared domain contracts without exercising native view rendering.
final class NativeDomainContractsTests: XCTestCase
{
    /// Completes the real debounce and detached renderer without network access or user photos.
    func testPreviewTaskReturnsCompletedPixels() async throws
    {
        let source = try image(color: .systemBlue)
        let result = try await PhotoProcessingTask.render(
            source: source,
            settings: PhotoAdjustmentSettings(),
            cachedMask: nil
        )
        XCTAssertEqual(result.image.width, 12)
        XCTAssertEqual(result.image.height, 8)
    }

    /// Keeps reset-state detection consistent for each independently adjustable tone control.
    func testAdjustmentStateAndReset()
    {
        let keys: [WritableKeyPath<PhotoAdjustmentSettings, Double>] = [
            \.exposure, \.contrast, \.highlights, \.shadows, \.saturation, \.hue, \.sharpness, \.angle
        ]
        for key in keys
        {
            var settings = PhotoAdjustmentSettings()
            XCTAssertTrue(settings.isDefault)
            settings[keyPath: key] += 0.1
            XCTAssertTrue(settings.hasToneChanges)
            XCTAssertFalse(settings.isDefault)
        }
        var settings = PhotoAdjustmentSettings()
        settings.background = .white
        XCTAssertFalse(settings.isDefault)
        XCTAssertFalse(settings.hasToneChanges)
    }

    /// Checks that native preview colors agree with the exported Core Graphics palette.
    func testPalettePreviewAndExportAgree() throws
    {
        for color in DecorationColor.allCases
        {
            let preview = try XCTUnwrap(NSColor(color.color).usingColorSpace(.deviceRGB))
            let exported = try XCTUnwrap(NSColor(cgColor: color.cgColor)?.usingColorSpace(.deviceRGB))
            XCTAssertEqual(preview.redComponent, exported.redComponent, accuracy: 0.01)
            XCTAssertEqual(preview.greenComponent, exported.greenComponent, accuracy: 0.01)
            XCTAssertEqual(preview.blueComponent, exported.blueComponent, accuracy: 0.01)
            XCTAssertFalse(color.title.isEmpty)
            XCTAssertEqual(color.id, color)
        }
    }

    /// Reuses an all-background mask to check solid replacement without nondeterministic Vision detection.
    func testCachedMaskUsesEveryBackgroundColor() throws
    {
        let source = try image(color: .systemBlue)
        let mask = try image(color: .black)
        for background in ReplacementBackground.allCases where background != .original
        {
            var settings = PhotoAdjustmentSettings()
            settings.background = background
            let result = try LocalPhotoProcessor.render(source: source, settings: settings, cachedPersonMask: mask)
            let pixel = try XCTUnwrap(NSBitmapImageRep(cgImage: result.image).colorAt(x: 0, y: 0))
            XCTAssertEqual(pixel.redComponent, try XCTUnwrap(background.color).red, accuracy: 0.02)
            XCTAssertEqual(result.image.width, source.width)
            XCTAssertEqual(background.id, background)
        }
    }

    /// Gives users an action for each recoverable rendering, input, catalog, and preview failure.
    func testErrorsIncludeARecoveryAction()
    {
        for error in recoverableErrors
        {
            let message = error.errorDescription?.lowercased() ?? ""
            XCTAssertTrue(
                ["select", "choose", "try", "reset", "check", "use", "allow"].contains(where: message.contains),
                message
            )
        }
    }

    /// User-visible failure cases remain separate from transport errors supplied by the system.
    private var recoverableErrors: [any LocalizedError]
    {
        [
            ImageExportError.unreadableImage,
            ImageExportError.invalidCrop,
            ImageExportError.encodingFailed,
            PhotoProcessingError.noPersonFound,
            PhotoProcessingError.renderFailed,
            PrintSheetError.missingPhysicalSize,
            PrintSheetError.photoDoesNotFit,
            PrintSheetError.outputTooLarge,
            PrintSheetError.renderingFailed,
            PrintSheetError.encodingFailed,
            ResourceError.unsupportedCatalog,
            ResourceError.emptyCatalog,
            ResourceError.duplicateIdentifier,
            ResourceError.disallowedLicense,
            ResourceError.missingAttribution,
            ResourceError.invalidIdentifier,
            ResourceError.unsupportedFile,
            ResourceError.missingFontName,
            PreviewError.invalidArguments,
            PreviewError.existingDestination,
            PreviewError.missingVideoTrack,
            PreviewError.cannotCreateExporter,
            MobilePhotoError.unreadableImage, MobilePhotoError.invalidCrop, MobilePhotoError.renderFailed,
            MobilePhotoError.photosAccessDenied, DecorationRenderError.renderFailed
        ]
    }

    /// Uses tiny bounded images so color and cancellation tests stay deterministic and inexpensive.
    private func image(color: NSColor) throws -> CGImage
    {
        let context = try XCTUnwrap(BitmapCanvas.make(size: CGSize(width: 12, height: 8)))
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 12, height: 8))
        return try XCTUnwrap(context.makeImage())
    }
}
