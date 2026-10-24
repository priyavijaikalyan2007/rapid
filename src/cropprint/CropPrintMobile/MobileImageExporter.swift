// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: e5253588-2159-4582-b801-38f8a426521d
// Created: 2026
// COMPONENT: MobileImageExporter
// PURPOSE: Prepares cropped mobile pixels and physical sheet rasters for add-only Photos saves.
// RELATES: [[CropPrint]]
// FLOW: Native application -> MobileImageExporter -> local result.

import CoreGraphics
import Foundation

/// Prepares cropped mobile pixels and physical sheet rasters for add-only Photos saves.
enum MobileImageExporter
{
    /// Renders a bounded print-sheet raster and returns its actual copy count.
    static func renderPrintSheet(
        photo: MobilePhoto,
        sourceImage: CGImage,
        normalizedCrop: CGRect,
        settings: PrintSettings,
        decoration: DecorationSettings,
        remoteFrameURL: URL?,
        sheetSettings: PrintSheetSettings
    ) throws -> (image: CGImage, copyCount: Int)
    {
        guard settings.preset.physicalInches != nil
        else
        {
            throw PrintSheetError.missingPhysicalSize
        }
        let preparedPhoto = try render(
            photo: photo,
            sourceImage: sourceImage,
            normalizedCrop: normalizedCrop,
            settings: settings,
            decoration: decoration,
            remoteFrameURL: remoteFrameURL
        )
        let physicalSize = settings.preset.dimensions(for: settings.orientation)
        let layout = try PrintSheetLayout.make(
            photoSizeInches: physicalSize,
            settings: sheetSettings
        )
        return try renderedSheet(photo: preparedPhoto, layout: layout, settings: sheetSettings)
    }

    /// Produces decorated output pixels and throws when validation or rendering fails.
    static func render(
        photo: MobilePhoto,
        sourceImage: CGImage,
        normalizedCrop: CGRect,
        settings: PrintSettings,
        decoration: DecorationSettings,
        remoteFrameURL: URL?
    ) throws -> CGImage
    {
        let prepared = try croppedImage(sourceImage, crop: normalizedCrop, settings: settings)
        let finalImage: CGImage
        if let target = settings.outputPixels
        {
            finalImage = try draw(prepared, canvasSize: target, inset: 0)
        }
        else
        {
            finalImage = prepared
        }
        return try DecorationRenderer.render(
            image: finalImage,
            settings: decoration,
            remoteFrameURL: remoteFrameURL
        )
    }

    /// Fits source pixels inside the selected quarter-inch white margin.
    private static func addMargin(to image: CGImage, settings: PrintSettings) throws -> CGImage
    {
        guard let baseSize = settings.preset.physicalInches
        else
        {
            return image
        }
        let physicalSize = settings.orientation == .portrait
            ? baseSize
            : CGSize(width: baseSize.height, height: baseSize.width)
        let pixelsPerInch = min(
            CGFloat(image.width) / physicalSize.width,
            CGFloat(image.height) / physicalSize.height
        )
        let inset = CGFloat(max(1, Int((0.25 * pixelsPerInch).rounded())))
        return try draw(
            image,
            canvasSize: CGSize(width: image.width, height: image.height),
            inset: inset
        )
    }

    /// Draws source pixels into the destination context at the supplied scale.
    private static func draw(_ image: CGImage, canvasSize: CGSize, inset: CGFloat) throws -> CGImage
    {
        let width = canvasSize.width.rounded()
        let height = canvasSize.height.rounded()
        let availableWidth = max(1, CGFloat(width) - inset * 2)
        let availableHeight = max(1, CGFloat(height) - inset * 2)
        let scale = min(
            availableWidth / CGFloat(image.width),
            availableHeight / CGFloat(image.height)
        )
        let drawSize = CGSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
        let drawRect = CGRect(
            x: (CGFloat(width) - drawSize.width) / 2,
            y: (CGFloat(height) - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )

        guard let context = BitmapCanvas.make(size: CGSize(width: width, height: height), alpha: .premultipliedLast)
        else
        {
            throw MobilePhotoError.renderFailed
        }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high
        context.draw(image, in: drawRect)
        return try completedImage(from: context)
    }

    /// Validates and crops source pixels before the optional physical inside margin.
    private static func croppedImage(_ sourceImage: CGImage, crop: CGRect, settings: PrintSettings) throws -> CGImage
    {
        let pixelRect = CropGeometry.pixelCrop(
            from: crop,
            imageSize: CGSize(width: sourceImage.width, height: sourceImage.height)
        )
        guard pixelRect.width > 0, pixelRect.height > 0,
              let cropped = sourceImage.cropping(to: pixelRect)
        else
        {
            throw MobilePhotoError.invalidCrop
        }

        let prepared: CGImage
        if settings.isPrintPreset && settings.includesMargin
        {
            prepared = try addMargin(to: cropped, settings: settings)
        }
        else
        {
            prepared = cropped
        }
        return prepared
    }

    /// Returns completed pixels or a recoverable renderer-specific allocation failure.
    private static func completedImage(from context: CGContext) throws -> CGImage
    {
        guard let image = context.makeImage()
        else
        {
            throw MobilePhotoError.renderFailed
        }
        return image
    }

    /// Couples the completed raster with its physical layout copy count.
    private static func renderedSheet(
        photo preparedPhoto: CGImage,
        layout: PrintSheetLayout,
        settings sheetSettings: PrintSheetSettings
    ) throws -> (image: CGImage, copyCount: Int)
    {
        let image = try PrintSheetRenderer.rasterImage(
            photo: preparedPhoto,
            layout: layout,
            settings: sheetSettings
        )
        return (image, layout.copyCount)
    }
}
