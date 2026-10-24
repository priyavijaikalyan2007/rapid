// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4587350a-a515-4ead-9b55-3fe312734266
// Created: 2026
// COMPONENT: PrintSheetRenderer
// PURPOSE: Renders physical photo placements as bounded JPEG pixels or resolution-independent PDF pages.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PrintSheetRenderer -> local result.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Renders physical photo placements as bounded JPEG pixels or resolution-independent PDF pages.
enum PrintSheetRenderer
{
    /// Renders all sheet copies after checking the output pixel budget.
    static func rasterImage(
        photo: CGImage,
        layout: PrintSheetLayout,
        settings: PrintSheetSettings
    ) throws -> CGImage
    {
        guard layout.canRenderRaster(at: settings.resolution)
        else
        {
            throw PrintSheetError.outputTooLarge
        }
        let pixelsPerInch = CGFloat(settings.resolution.rawValue)
        let width = Int((layout.pageSizeInches.width * pixelsPerInch).rounded())
        let height = Int((layout.pageSizeInches.height * pixelsPerInch).rounded())

        guard let context = BitmapCanvas.make(size: CGSize(width: width, height: height), alpha: .noneSkipLast)
        else
        {
            throw PrintSheetError.renderingFailed
        }

        draw(
            photo: photo,
            layout: layout,
            settings: settings,
            in: context,
            unitsPerInch: pixelsPerInch
        )
        return try completedImage(from: context)
    }

    /// Encodes a print-sheet JPEG with its sampling density metadata.
    static func jpegData(
        for image: CGImage,
        resolution: PrintSheetResolution
    ) throws -> Data
    {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else
        {
            throw PrintSheetError.encodingFailed
        }

        let properties = jpegProperties(resolution: resolution)
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination)
        else
        {
            throw PrintSheetError.encodingFailed
        }
        return data as Data
    }

    /// Creates a PDF whose page geometry preserves physical print dimensions.
    static func pdfData(
        photo: CGImage,
        layout: PrintSheetLayout,
        settings: PrintSheetSettings
    ) throws -> Data
    {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData)
        else
        {
            throw PrintSheetError.encodingFailed
        }

        var mediaBox = CGRect(
            origin: .zero,
            size: CGSize(
                width: layout.pageSizeInches.width * 72,
                height: layout.pageSizeInches.height * 72
            )
        )
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else
        {
            throw PrintSheetError.renderingFailed
        }

        context.beginPDFPage(nil)
        draw(photo: photo, layout: layout, settings: settings, in: context, unitsPerInch: 72)
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }

    /// Draws source pixels into the destination context at the supplied scale.
    private static func draw(
        photo: CGImage,
        layout: PrintSheetLayout,
        settings: PrintSheetSettings,
        in context: CGContext,
        unitsPerInch: CGFloat
    )
    {
        let pageRect = CGRect(
            origin: .zero,
            size: CGSize(
                width: layout.pageSizeInches.width * unitsPerInch,
                height: layout.pageSizeInches.height * unitsPerInch
            )
        )
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(pageRect)
        context.interpolationQuality = .high

        for rectInches in layout.photoRectsInches
        {
            let rect = scaled(rectInches, by: unitsPerInch)
            context.draw(photo, in: rect)
            if settings.includesCutGuides
            {
                drawCutGuides(around: rect, in: context, unitsPerInch: unitsPerInch)
            }
        }
    }

    /// Converts physical rectangles to the renderer coordinate units.
    private static func scaled(_ rect: CGRect, by scale: CGFloat) -> CGRect
    {
        CGRect(
            x: rect.minX * scale,
            y: rect.minY * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
    }

    /// Draws short cutting marks outside each photo at physical print scale.
    private static func drawCutGuides(
        around rect: CGRect,
        in context: CGContext,
        unitsPerInch: CGFloat
    )
    {
        let gap = 0.025 * unitsPerInch
        let length = 0.075 * unitsPerInch
        context.saveGState()
        context.setStrokeColor(CGColor(gray: 0.35, alpha: 1))
        context.setLineWidth(max(0.5, unitsPerInch / 300))

        for x in [rect.minX, rect.maxX]
        {
            context.move(to: CGPoint(x: x, y: rect.minY - gap))
            context.addLine(to: CGPoint(x: x, y: rect.minY - gap - length))
            context.move(to: CGPoint(x: x, y: rect.maxY + gap))
            context.addLine(to: CGPoint(x: x, y: rect.maxY + gap + length))
        }
        for y in [rect.minY, rect.maxY]
        {
            context.move(to: CGPoint(x: rect.minX - gap, y: y))
            context.addLine(to: CGPoint(x: rect.minX - gap - length, y: y))
            context.move(to: CGPoint(x: rect.maxX + gap, y: y))
            context.addLine(to: CGPoint(x: rect.maxX + gap + length, y: y))
        }
        context.strokePath()
        context.restoreGState()
    }

    /// Encodes physical sampling density in both standard image and JFIF metadata.
    private static func jpegProperties(resolution: PrintSheetResolution) -> [CFString: Any]
    {
        let pixelsPerInch = resolution.rawValue
        return [
            kCGImageDestinationLossyCompressionQuality: 0.98,
            kCGImagePropertyDPIWidth: pixelsPerInch,
            kCGImagePropertyDPIHeight: pixelsPerInch,
            kCGImagePropertyJFIFDictionary: [
                kCGImagePropertyJFIFDensityUnit: 1,
                kCGImagePropertyJFIFXDensity: pixelsPerInch,
                kCGImagePropertyJFIFYDensity: pixelsPerInch
            ]
        ]
    }

    /// Returns completed pixels or a recoverable renderer-specific allocation failure.
    private static func completedImage(from context: CGContext) throws -> CGImage
    {
        guard let image = context.makeImage()
        else
        {
            throw PrintSheetError.renderingFailed
        }
        return image
    }
}
