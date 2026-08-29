import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum ImageExportError: LocalizedError {
    case unreadableImage
    case invalidCrop
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .unreadableImage: "The app could not read this image."
        case .invalidCrop: "The crop area is not valid."
        case .encodingFailed: "The app could not encode the cropped image."
        }
    }
}

struct LoadedPhoto {
    let image: NSImage
    let cgImage: CGImage
    let sourceURL: URL

    var pixelSize: CGSize {
        CGSize(width: cgImage.width, height: cgImage.height)
    }

    init(url: URL) throws {
        guard let image = NSImage(contentsOf: url) else {
            throw ImageExportError.unreadableImage
        }

        var proposedRect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            throw ImageExportError.unreadableImage
        }

        self.image = image
        self.cgImage = cgImage
        self.sourceURL = url
    }
}

struct PrintSheetOutput {
    let jpegURL: URL
    let pdfURL: URL
    let copyCount: Int
}

enum ImageExporter {
    static func createPrintSheet(
        photo: LoadedPhoto,
        normalizedCrop: CGRect,
        settings: PrintSettings,
        decoration: DecorationSettings,
        remoteFrameURL: URL?,
        sheetSettings: PrintSheetSettings
    ) throws -> PrintSheetOutput {
        guard settings.preset.physicalInches != nil else {
            throw PrintSheetError.missingPhysicalSize
        }

        let pixelRect = CropGeometry.pixelCrop(
            from: normalizedCrop,
            imageSize: photo.pixelSize
        )
        guard pixelRect.width > 0, pixelRect.height > 0,
              let cropped = photo.cgImage.cropping(to: pixelRect) else {
            throw ImageExportError.invalidCrop
        }

        let preparedImage: CGImage
        if settings.isPrintPreset && settings.includesMargin {
            preparedImage = try imageByAddingMargin(to: cropped, settings: settings)
        } else {
            preparedImage = cropped
        }
        let decoratedImage = try DecorationRenderer.render(
            image: preparedImage,
            settings: decoration,
            remoteFrameURL: remoteFrameURL
        )
        let orientedPhotoSize = settings.preset.dimensions(for: settings.orientation)
        let layout = try PrintSheetLayout.make(
            photoSizeInches: orientedPhotoSize,
            settings: sheetSettings
        )
        let raster = try PrintSheetRenderer.rasterImage(
            photo: decoratedImage,
            layout: layout,
            settings: sheetSettings
        )
        let jpegData = try PrintSheetRenderer.jpegData(
            for: raster,
            resolution: sheetSettings.resolution
        )
        let pdfData = try PrintSheetRenderer.pdfData(
            photo: decoratedImage,
            layout: layout,
            settings: sheetSettings
        )
        let urls = availablePrintSheetURLs(
            for: photo.sourceURL,
            settings: sheetSettings
        )
        try jpegData.write(to: urls.jpeg, options: .atomic)
        try pdfData.write(to: urls.pdf, options: .atomic)
        return PrintSheetOutput(
            jpegURL: urls.jpeg,
            pdfURL: urls.pdf,
            copyCount: layout.copyCount
        )
    }

    static func export(
        photo: LoadedPhoto,
        normalizedCrop: CGRect,
        settings: PrintSettings,
        decoration: DecorationSettings,
        remoteFrameURL: URL?
    ) throws -> URL {
        let pixelRect = CropGeometry.pixelCrop(
            from: normalizedCrop,
            imageSize: photo.pixelSize
        )

        guard pixelRect.width > 0, pixelRect.height > 0,
              let cropped = photo.cgImage.cropping(to: pixelRect) else {
            throw ImageExportError.invalidCrop
        }

        let preparedImage: CGImage
        if settings.isPrintPreset && settings.includesMargin {
            preparedImage = try imageByAddingMargin(to: cropped, settings: settings)
        } else {
            preparedImage = cropped
        }
        let finalImage = try settings.outputPixels.map {
            try resizedImage(preparedImage, to: $0)
        } ?? preparedImage
        let decoratedImage = try DecorationRenderer.render(
            image: finalImage,
            settings: decoration,
            remoteFrameURL: remoteFrameURL
        )
        let decorationSuffix = decoration.hasDecorations ? "-decorated" : ""
        let outputURL = availableOutputURL(for: photo.sourceURL, suffix: settings.fileSuffix + decorationSuffix)
        let data = try encodedData(for: decoratedImage, preferredExtension: photo.sourceURL.pathExtension)
        try data.write(to: outputURL, options: .atomic)
        return outputURL
    }

    private static func imageByAddingMargin(to image: CGImage, settings: PrintSettings) throws -> CGImage {
        guard let baseSize = settings.preset.physicalInches else { return image }
        let physicalSize = settings.orientation == .portrait
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
        let drawRect = CGRect(
            x: (CGFloat(canvasWidth) - drawWidth) / 2,
            y: (CGFloat(canvasHeight) - drawHeight) / 2,
            width: drawWidth,
            height: drawHeight
        )

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: canvasWidth,
                height: canvasHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw ImageExportError.encodingFailed
        }

        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        context.interpolationQuality = .high
        context.draw(image, in: drawRect)

        guard let result = context.makeImage() else {
            throw ImageExportError.encodingFailed
        }
        return result
    }

    private static func resizedImage(_ image: CGImage, to size: CGSize) throws -> CGImage {
        let width = Int(size.width.rounded())
        let height = Int(size.height.rounded())
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
            throw ImageExportError.encodingFailed
        }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let result = context.makeImage() else {
            throw ImageExportError.encodingFailed
        }
        return result
    }

    private static func encodedData(for image: CGImage, preferredExtension: String) throws -> Data {
        let lowercasedExtension = preferredExtension.lowercased()
        if lowercasedExtension == "heic" || lowercasedExtension == "heif" {
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                data,
                UTType.heic.identifier as CFString,
                1,
                nil
            ) else {
                throw ImageExportError.encodingFailed
            }
            let properties = [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary
            CGImageDestinationAddImage(destination, image, properties)
            guard CGImageDestinationFinalize(destination) else {
                throw ImageExportError.encodingFailed
            }
            return data as Data
        }

        let representation = NSBitmapImageRep(cgImage: image)
        let fileType: NSBitmapImageRep.FileType
        let properties: [NSBitmapImageRep.PropertyKey: Any]

        switch lowercasedExtension {
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

        guard let data = representation.representation(using: fileType, properties: properties) else {
            throw ImageExportError.encodingFailed
        }
        return data
    }

    private static func availableOutputURL(for sourceURL: URL, suffix: String) -> URL {
        let directory = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let sourceExtension = normalizedExtension(sourceURL.pathExtension)
        var candidate = directory.appendingPathComponent("\(baseName)-\(suffix).\(sourceExtension)")
        var copyNumber = 2

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(baseName)-\(suffix)-\(copyNumber).\(sourceExtension)")
            copyNumber += 1
        }
        return candidate
    }

    private static func availablePrintSheetURLs(
        for sourceURL: URL,
        settings: PrintSheetSettings
    ) -> (jpeg: URL, pdf: URL) {
        let directory = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let suffix = "print-sheet-\(settings.paperSize.fileLabel)-\(settings.paperOrientation.rawValue)-\(settings.resolution.rawValue)ppi"
        var stem = "\(baseName)-\(suffix)"
        var jpeg = directory.appendingPathComponent("\(stem).jpg")
        var pdf = directory.appendingPathComponent("\(stem).pdf")
        var copyNumber = 2

        while FileManager.default.fileExists(atPath: jpeg.path)
            || FileManager.default.fileExists(atPath: pdf.path) {
            stem = "\(baseName)-\(suffix)-\(copyNumber)"
            jpeg = directory.appendingPathComponent("\(stem).jpg")
            pdf = directory.appendingPathComponent("\(stem).pdf")
            copyNumber += 1
        }
        return (jpeg, pdf)
    }

    private static func normalizedExtension(_ sourceExtension: String) -> String {
        let value = sourceExtension.lowercased()
        switch value {
        case "png", "tif", "tiff", "heic", "heif", "jpg", "jpeg": return value
        default: return "jpg"
        }
    }
}
