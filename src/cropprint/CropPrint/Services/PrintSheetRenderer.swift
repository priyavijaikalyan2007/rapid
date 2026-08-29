import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PrintSheetRenderer {
    static func rasterImage(
        photo: CGImage,
        layout: PrintSheetLayout,
        settings: PrintSheetSettings
    ) throws -> CGImage {
        guard layout.canRenderRaster(at: settings.resolution) else {
            throw PrintSheetError.outputTooLarge
        }
        let pixelsPerInch = CGFloat(settings.resolution.rawValue)
        let width = Int((layout.pageSizeInches.width * pixelsPerInch).rounded())
        let height = Int((layout.pageSizeInches.height * pixelsPerInch).rounded())

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              ) else {
            throw PrintSheetError.renderingFailed
        }

        draw(
            photo: photo,
            layout: layout,
            settings: settings,
            in: context,
            unitsPerInch: pixelsPerInch
        )
        guard let image = context.makeImage() else {
            throw PrintSheetError.renderingFailed
        }
        return image
    }

    static func jpegData(
        for image: CGImage,
        resolution: PrintSheetResolution
    ) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw PrintSheetError.encodingFailed
        }

        let pixelsPerInch = resolution.rawValue
        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.98,
            kCGImagePropertyDPIWidth: pixelsPerInch,
            kCGImagePropertyDPIHeight: pixelsPerInch,
            kCGImagePropertyJFIFDictionary: [
                kCGImagePropertyJFIFDensityUnit: 1,
                kCGImagePropertyJFIFXDensity: pixelsPerInch,
                kCGImagePropertyJFIFYDensity: pixelsPerInch
            ]
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw PrintSheetError.encodingFailed
        }
        return data as Data
    }

    static func pdfData(
        photo: CGImage,
        layout: PrintSheetLayout,
        settings: PrintSheetSettings
    ) throws -> Data {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            throw PrintSheetError.encodingFailed
        }

        var mediaBox = CGRect(
            origin: .zero,
            size: CGSize(
                width: layout.pageSizeInches.width * 72,
                height: layout.pageSizeInches.height * 72
            )
        )
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PrintSheetError.renderingFailed
        }

        context.beginPDFPage(nil)
        draw(photo: photo, layout: layout, settings: settings, in: context, unitsPerInch: 72)
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }

    private static func draw(
        photo: CGImage,
        layout: PrintSheetLayout,
        settings: PrintSheetSettings,
        in context: CGContext,
        unitsPerInch: CGFloat
    ) {
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

        for rectInches in layout.photoRectsInches {
            let rect = scaled(rectInches, by: unitsPerInch)
            context.draw(photo, in: rect)
            if settings.includesCutGuides {
                drawCutGuides(around: rect, in: context, unitsPerInch: unitsPerInch)
            }
        }
    }

    private static func scaled(_ rect: CGRect, by scale: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX * scale,
            y: rect.minY * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
    }

    private static func drawCutGuides(
        around rect: CGRect,
        in context: CGContext,
        unitsPerInch: CGFloat
    ) {
        let gap = 0.025 * unitsPerInch
        let length = 0.075 * unitsPerInch
        context.saveGState()
        context.setStrokeColor(CGColor(gray: 0.35, alpha: 1))
        context.setLineWidth(max(0.5, unitsPerInch / 300))

        for x in [rect.minX, rect.maxX] {
            context.move(to: CGPoint(x: x, y: rect.minY - gap))
            context.addLine(to: CGPoint(x: x, y: rect.minY - gap - length))
            context.move(to: CGPoint(x: x, y: rect.maxY + gap))
            context.addLine(to: CGPoint(x: x, y: rect.maxY + gap + length))
        }
        for y in [rect.minY, rect.maxY] {
            context.move(to: CGPoint(x: rect.minX - gap, y: y))
            context.addLine(to: CGPoint(x: rect.minX - gap - length, y: y))
            context.move(to: CGPoint(x: rect.maxX + gap, y: y))
            context.addLine(to: CGPoint(x: rect.maxX + gap + length, y: y))
        }
        context.strokePath()
        context.restoreGState()
    }
}
