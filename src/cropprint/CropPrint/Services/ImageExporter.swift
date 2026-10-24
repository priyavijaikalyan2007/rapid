// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f8745353-085a-4141-b414-155674b9a114
// Created: 2026
// COMPONENT: ImageExporter
// PURPOSE: Encodes cropped macOS images and publishes complete export files without overwriting existing files.
// RELATES: [[CropPrint]]
// FLOW: Native application -> ImageExporter -> local result.

import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Exports cropped macOS photos and physical print sheets.
enum ImageExporter
{
    /// Exports physical sheet files and reveals only completed outputs in Finder.
    static func createPrintSheet(
        photo: LoadedPhoto, sourceImage: CGImage, normalizedCrop: CGRect, settings: PrintSettings,
        decoration: DecorationSettings, remoteFrameURL: URL?, sheetSettings: PrintSheetSettings
    ) throws -> PrintSheetOutput
    {
        guard settings.preset.physicalInches != nil
        else
        {
            throw PrintSheetError.missingPhysicalSize
        }
        let image = try preparedSheetPhoto(
            sourceImage,
            crop: normalizedCrop,
            settings: settings,
            decoration: decoration,
            frame: remoteFrameURL
        )
        let layout = try PrintSheetLayout.make(
            photoSizeInches: settings.preset.dimensions(for: settings.orientation), settings: sheetSettings
        )
        return try writePrintSheet(for: photo.sourceURL, image: image, layout: layout, settings: sheetSettings)
    }

    /// Creates a new cropped image without replacing the original or an existing output.
    static func export(
        photo: LoadedPhoto, sourceImage: CGImage, normalizedCrop: CGRect,
        settings: PrintSettings, decoration: DecorationSettings, remoteFrameURL: URL?
    ) throws -> URL
    {
        let prepared = try preparedImage(sourceImage, crop: normalizedCrop, settings: settings)
        let finalImage = try settings.outputPixels.map
        {
            try resizedImage(prepared, to: $0)
        } ?? prepared
        let decorated = try DecorationRenderer.render(
            image: finalImage,
            settings: decoration,
            remoteFrameURL: remoteFrameURL
        )
        let suffix = settings.fileSuffix + (decoration.hasDecorations ? "-decorated" : "")
        let destination = availableOutputURL(for: photo.sourceURL, suffix: suffix)
        let data = try encodedData(for: decorated, preferredExtension: photo.sourceURL.pathExtension)
        try ExportFileWriter.write([(data, destination)])
        return destination
    }

    /// Fits the photo inside a quarter-inch white border within the selected canvas.
    private static func imageByAddingMargin(to image: CGImage, settings: PrintSettings) throws -> CGImage
    {
        guard let baseSize = settings.preset.physicalInches
        else
        {
            return image
        }
        let canvasWidth = image.width
        let canvasHeight = image.height
        let drawRect = marginRectangle(image: image, baseSize: baseSize, orientation: settings.orientation)

        guard let context = BitmapCanvas.make(
            size: CGSize(width: canvasWidth, height: canvasHeight),
            alpha: .premultipliedLast
        ) else
        {
            throw ImageExportError.encodingFailed
        }

        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        context.interpolationQuality = .high
        context.draw(image, in: drawRect)

        guard let result = context.makeImage()
        else
        {
            throw ImageExportError.encodingFailed
        }
        return result
    }

    /// Resamples into a bounded bitmap at the exact requested output size.
    private static func resizedImage(_ image: CGImage, to size: CGSize) throws -> CGImage
    {
        guard let context = BitmapCanvas.make(size: size, alpha: .premultipliedLast)
        else
        {
            throw ImageExportError.encodingFailed
        }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: context.width, height: context.height))
        guard let result = context.makeImage()
        else
        {
            throw ImageExportError.encodingFailed
        }
        return result
    }

    /// Encodes pixels using a supported source format and a JPEG fallback.
    private static func encodedData(for image: CGImage, preferredExtension: String) throws -> Data
    {
        let lowercasedExtension = preferredExtension.lowercased()
        if lowercasedExtension == "heic" || lowercasedExtension == "heif"
        {
            return try heicData(for: image)
        }

        let representation = NSBitmapImageRep(cgImage: image)
        let fileType: NSBitmapImageRep.FileType
        let properties: [NSBitmapImageRep.PropertyKey: Any]

        switch lowercasedExtension
        {
        case "png":
            fileType = .png
            properties = [:]
        case "tif", "tiff":
            fileType = .tiff
            properties = [:]
        default:
            fileType = .jpeg
            properties = [.compressionFactor: 0.95]
        }

        guard let data = representation.representation(using: fileType, properties: properties)
        else
        {
            throw ImageExportError.encodingFailed
        }
        return data
    }

    /// Chooses a readable unused export name before exclusive file publication.
    private static func availableOutputURL(for sourceURL: URL, suffix: String) -> URL
    {
        let directory = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let sourceExtension = normalizedExtension(sourceURL.pathExtension)
        var candidate = directory.appendingPathComponent("\(baseName)-\(suffix).\(sourceExtension)")
        var copyNumber = 2

        while FileManager.default.fileExists(atPath: candidate.path)
        {
            candidate = directory.appendingPathComponent("\(baseName)-\(suffix)-\(copyNumber).\(sourceExtension)")
            copyNumber += 1
        }
        return candidate
    }

    /// Chooses matching unused PDF and JPEG paths for one sheet export.
    private static func availablePrintSheetURLs(
        for sourceURL: URL,
        settings: PrintSheetSettings
    ) -> (jpeg: URL, pdf: URL)
    {
        let directory = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let suffix = "print-sheet-\(settings.paperSize.fileLabel)-\(settings.paperOrientation.rawValue)-\(settings.resolution.rawValue)ppi"
        var stem = "\(baseName)-\(suffix)"
        var jpeg = directory.appendingPathComponent("\(stem).jpg")
        var pdf = directory.appendingPathComponent("\(stem).pdf")
        var copyNumber = 2

        while FileManager.default.fileExists(atPath: jpeg.path)
            || FileManager.default.fileExists(atPath: pdf.path)
        {
            stem = "\(baseName)-\(suffix)-\(copyNumber)"
            jpeg = directory.appendingPathComponent("\(stem).jpg")
            pdf = directory.appendingPathComponent("\(stem).pdf")
            copyNumber += 1
        }
        return (jpeg, pdf)
    }

    /// Preserves supported image extensions and falls back to JPEG otherwise.
    private static func normalizedExtension(_ sourceExtension: String) -> String
    {
        let value = sourceExtension.lowercased()
        switch value
        {
        case "png", "tif", "tiff", "heic", "heif", "jpg", "jpeg": return value
        default: return "jpg"
        }
    }

    /// Applies shared crop validation and the optional inside margin before decoration.
    private static func preparedImage(
        _ image: CGImage, crop: CGRect, settings: PrintSettings
    ) throws -> CGImage
    {
        let rectangle = CropGeometry.pixelCrop(from: crop, imageSize: CGSize(width: image.width, height: image.height))
        guard rectangle.width > 0, rectangle.height > 0, let cropped = image.cropping(to: rectangle)
        else
        {
            throw ImageExportError.invalidCrop
        }
        return try settings.isPrintPreset && settings.includesMargin
            ? imageByAddingMargin(to: cropped, settings: settings) : cropped
    }

    /// Preserves source crop pixels for physical print-sheet rendering.
    private static func preparedSheetPhoto(
        _ image: CGImage, crop: CGRect, settings: PrintSettings, decoration: DecorationSettings, frame: URL?
    ) throws -> CGImage
    {
        let prepared = try preparedImage(image, crop: crop, settings: settings)
        return try DecorationRenderer.render(image: prepared, settings: decoration, remoteFrameURL: frame)
    }

    /// Encodes every requested output before publishing any destination.
    private static func writePrintSheet(
        for source: URL, image: CGImage, layout: PrintSheetLayout, settings: PrintSheetSettings
    ) throws -> PrintSheetOutput
    {
        let urls = availablePrintSheetURLs(for: source, settings: settings)
        let pdf = try PrintSheetRenderer.pdfData(photo: image, layout: layout, settings: settings)
        var outputs: [(data: Data, url: URL)] = [(pdf, urls.pdf)]
        let jpeg = try printSheetJPEG(image, layout: layout, settings: settings)
        if let jpeg
        {
            outputs.append((jpeg, urls.jpeg))
        }
        try ExportFileWriter.write(outputs)
        return PrintSheetOutput(jpegURL: jpeg == nil ? nil : urls.jpeg, pdfURL: urls.pdf, copyCount: layout.copyCount)
    }

    /// Keeps the existing PDF-only fallback when the configured raster exceeds its safe budget.
    private static func printSheetJPEG(
        _ image: CGImage, layout: PrintSheetLayout, settings: PrintSheetSettings
    ) throws -> Data?
    {
        guard layout.canRenderRaster(at: settings.resolution)
        else
        {
            return nil
        }
        let raster = try PrintSheetRenderer.rasterImage(photo: image, layout: layout, settings: settings)
        return try PrintSheetRenderer.jpegData(for: raster, resolution: settings.resolution)
    }

    /// Uses ImageIO for HEIC output because AppKit has no HEIC bitmap file type.
    private static func heicData(for image: CGImage) throws -> Data
    {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.heic.identifier as CFString,
            1,
            nil
        ) else
        {
            throw ImageExportError.encodingFailed
        }
        let properties = [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination)
        else
        {
            throw ImageExportError.encodingFailed
        }
        return data as Data
    }

    /// Fits the source inside a quarter-inch white border without changing the selected canvas size.
    private static func marginRectangle(image: CGImage, baseSize: CGSize, orientation: PrintOrientation) -> CGRect
    {
        let physicalSize = orientation == .portrait
            ? baseSize
            : CGSize(width: baseSize.height, height: baseSize.width)
        let pixelsPerInch = min(
            CGFloat(image.width) / physicalSize.width,
            CGFloat(image.height) / physicalSize.height
        )
        let marginPixels = max(1, Int((0.25 * pixelsPerInch).rounded()))
        let canvasWidth = image.width
        let canvasHeight = image.height
        let availableWidth = max(1, canvasWidth - marginPixels * 2)
        let availableHeight = max(1, canvasHeight - marginPixels * 2)
        let scale = min(
            CGFloat(availableWidth) / CGFloat(image.width),
            CGFloat(availableHeight) / CGFloat(image.height)
        )
        let drawWidth = CGFloat(image.width) * scale
        let drawHeight = CGFloat(image.height) * scale
        return CGRect(
            x: (CGFloat(canvasWidth) - drawWidth) / 2,
            y: (CGFloat(canvasHeight) - drawHeight) / 2,
            width: drawWidth,
            height: drawHeight
        )
    }
}
