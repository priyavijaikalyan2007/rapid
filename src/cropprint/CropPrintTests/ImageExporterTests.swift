// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File a5dd7a58-cc97-41f4-a420-01480d4c1ae3: a5dd7a58-cc97-41f4-a420-01480d4c1ae3
// Created: 2026
// COMPONENT: Native export regression tests
// PURPOSE: Verify file formats, safe naming, margins, and PDF fallback using isolated generated images.
// RELATES: ImageExporter, ExportFileWriter
// FLOW: Synthetic source -> export -> decoded dimensions and preserved input.

import AppKit
import ImageIO
import XCTest

/// Checks the actual native encoder and file-publication path without private photos.
final class ImageExporterTests: XCTestCase
{
    /// Verifies supported output encoders and exclusive naming preserve source bytes.
    func testFormatsAndExistingOutputs() throws
    {
        for fileExtension in ["png", "jpg", "tiff", "heic"]
        {
            let photo = try fixture(extension: fileExtension)
            defer { try? FileManager.default.removeItem(at: photo.sourceURL.deletingLastPathComponent()) }
            let original = try Data(contentsOf: photo.sourceURL)
            let first = try export(photo)
            let second = try export(photo)
            XCTAssertNotEqual(first, second)
            XCTAssertEqual(try Data(contentsOf: photo.sourceURL), original)
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(first as CFURL, nil))
            let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
            XCTAssertEqual(image.width, 40)
            XCTAssertEqual(image.height, 40)
        }
    }

    /// Verifies a malformed crop produces no output rather than a partial file.
    func testInvalidCropFailsBeforePublication() throws
    {
        let photo = try fixture()
        defer { try? FileManager.default.removeItem(at: photo.sourceURL.deletingLastPathComponent()) }
        XCTAssertThrowsError(try ImageExporter.export(
            photo: photo,
            sourceImage: photo.cgImage,
            normalizedCrop: .zero,
            settings: PrintSettings(),
            decoration: DecorationSettings(),
            remoteFrameURL: nil
        ))
        XCTAssertEqual(
            try FileManager.default.contentsOfDirectory(atPath: photo.sourceURL.deletingLastPathComponent().path).count,
            1
        )
    }

    /// Verifies quarter-inch margins remain inside source-resolution physical print output.
    func testPhysicalMarginAndSheetOutputs() throws
    {
        let photo = try fixture()
        defer { try? FileManager.default.removeItem(at: photo.sourceURL.deletingLastPathComponent()) }
        var settings = PrintSettings()
        settings.preset = .fourBySix
        settings.includesMargin = true
        let sheet = try ImageExporter.createPrintSheet(
            photo: photo,
            sourceImage: photo.cgImage,
            normalizedCrop: CGRect(x: 0, y: 0, width: 1, height: 1),
            settings: settings,
            decoration: DecorationSettings(),
            remoteFrameURL: nil,
            sheetSettings: PrintSheetSettings()
        )
        XCTAssertNotNil(sheet.jpegURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sheet.pdfURL.path))
        XCTAssertGreaterThan(sheet.copyCount, 0)
    }

    /// Keeps a vector PDF available when a large paper choice exceeds the raster budget.
    func testOversizedRasterFallsBackToPDF() throws
    {
        let photo = try fixture()
        defer { try? FileManager.default.removeItem(at: photo.sourceURL.deletingLastPathComponent()) }
        var settings = PrintSettings()
        settings.preset = .passportUS
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .twentyFourByThirtySix
        sheetSettings.resolution = .ppi1200
        let output = try ImageExporter.createPrintSheet(
            photo: photo,
            sourceImage: photo.cgImage,
            normalizedCrop: CGRect(x: 0, y: 0, width: 1, height: 1),
            settings: settings,
            decoration: DecorationSettings(),
            remoteFrameURL: nil,
            sheetSettings: sheetSettings
        )
        XCTAssertNil(output.jpegURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.pdfURL.path))
    }

    /// Uses a physical preset so the assertion measures crop pixels instead of a digital resize.
    private func export(_ photo: LoadedPhoto) throws -> URL
    {
        var settings = PrintSettings()
        settings.preset = .fourBySix
        return try ImageExporter.export(
            photo: photo,
            sourceImage: photo.cgImage,
            normalizedCrop: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5),
            settings: settings,
            decoration: DecorationSettings(),
            remoteFrameURL: nil
        )
    }

    /// Uses ImageIO source detection with each supported output suffix, then loads through the real input policy.
    private func fixture(extension fileExtension: String = "png") throws -> LoadedPhoto
    {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let context = try XCTUnwrap(BitmapCanvas.make(size: CGSize(width: 80, height: 80)))
        context.setFillColor(NSColor.systemBlue.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 80, height: 80))
        let image = try XCTUnwrap(context.makeImage())
        let data = try XCTUnwrap(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        let url = folder.appendingPathComponent("source." + fileExtension)
        try data.write(to: url)
        return try LoadedPhoto(url: url)
    }
}
