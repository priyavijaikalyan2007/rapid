import CoreGraphics
import Foundation

enum MobileImageExporter {
    static func renderPrintSheet(
        photo: MobilePhoto,
        sourceImage: CGImage,
        normalizedCrop: CGRect,
        settings: PrintSettings,
        decoration: DecorationSettings,
        remoteFrameURL: URL?,
        sheetSettings: PrintSheetSettings
    ) throws -> (image: CGImage, copyCount: Int) {
        guard settings.preset.physicalInches != nil else {
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
        let image = try PrintSheetRenderer.rasterImage(
            photo: preparedPhoto,
            layout: layout,
            settings: sheetSettings
        )
        return (image, layout.copyCount)
    }

    static func render(
        photo: MobilePhoto,
        sourceImage: CGImage,
        normalizedCrop: CGRect,
        settings: PrintSettings,
        decoration: DecorationSettings,
        remoteFrameURL: URL?
    ) throws -> CGImage {
        let pixelRect = CropGeometry.pixelCrop(
            from: normalizedCrop,
            imageSize: CGSize(width: sourceImage.width, height: sourceImage.height)
        )
        guard pixelRect.width > 0, pixelRect.height > 0,
              let cropped = sourceImage.cropping(to: pixelRect) else {
            throw MobilePhotoError.invalidCrop
        }

        let prepared: CGImage
        if settings.isPrintPreset && settings.includesMargin {
            prepared = try addMargin(to: cropped, settings: settings)
        } else {
            prepared = cropped
        }
        let finalImage: CGImage
        if let target = settings.outputPixels {
            finalImage = try draw(prepared, canvasSize: target, inset: 0)
        } else {
            finalImage = prepared
        }
        return try DecorationRenderer.render(
            image: finalImage,
            settings: decoration,
            remoteFrameURL: remoteFrameURL
        )
    }

    private static func addMargin(to image: CGImage, settings: PrintSettings) throws -> CGImage {
        guard let baseSize = settings.preset.physicalInches else { return image }
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

    private static func draw(_ image: CGImage, canvasSize: CGSize, inset: CGFloat) throws -> CGImage {
        let width = Int(canvasSize.width.rounded())
        let height = Int(canvasSize.height.rounded())
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

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw MobilePhotoError.renderFailed
        }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high
        context.draw(image, in: drawRect)
        guard let result = context.makeImage() else {
            throw MobilePhotoError.renderFailed
        }
        return result
    }
}
