import CoreGraphics
import Foundation

enum PrintSheetResolution: Int, CaseIterable, Identifiable {
    case ppi72 = 72
    case ppi96 = 96
    case ppi150 = 150
    case ppi200 = 200
    case ppi240 = 240
    case ppi300 = 300
    case ppi360 = 360
    case ppi600 = 600
    case ppi720 = 720
    case ppi1200 = 1200

    var id: Self { self }
    var title: String { "\(rawValue) PPI" }
}

enum PrinterResolution: Int, CaseIterable, Identifiable {
    case dpi300 = 300
    case dpi600 = 600
    case dpi720 = 720
    case dpi1200 = 1200
    case dpi1440 = 1440
    case dpi2400 = 2400
    case dpi4800 = 4800

    var id: Self { self }
    var title: String { "\(rawValue) DPI" }
}

struct PrintSheetSettings {
    var paperSize: PaperSize = .fiveBySeven
    var paperOrientation: PrintOrientation = .portrait
    var resolution: PrintSheetResolution = .ppi300
    var printerResolution: PrinterResolution = .dpi300
    var includesCutGuides = true
    var edgeInsetInches: CGFloat = 0.125
    var gutterInches: CGFloat = 0.125
}

enum PrintSheetError: LocalizedError {
    case missingPhysicalSize
    case photoDoesNotFit
    case outputTooLarge
    case renderingFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .missingPhysicalSize:
            "Select a print or physical passport size before creating a print sheet."
        case .photoDoesNotFit:
            "The selected photo size does not fit on this paper."
        case .outputTooLarge:
            "This paper and image PPI combination exceeds the safe raster limit."
        case .renderingFailed:
            "The app could not render the print sheet."
        case .encodingFailed:
            "The app could not encode the print sheet."
        }
    }
}

struct PrintSheetLayout {
    static let maximumRasterPixelCount: Int64 = 80_000_000
    let pageSizeInches: CGSize
    let photoSizeInches: CGSize
    let photoRectsInches: [CGRect]

    var copyCount: Int { photoRectsInches.count }

    func rasterPixelSize(at resolution: PrintSheetResolution) -> CGSize {
        let pixelsPerInch = CGFloat(resolution.rawValue)
        return CGSize(
            width: (pageSizeInches.width * pixelsPerInch).rounded(),
            height: (pageSizeInches.height * pixelsPerInch).rounded()
        )
    }

    func estimatedRasterBytes(at resolution: PrintSheetResolution) -> Int64? {
        let size = rasterPixelSize(at: resolution)
        let width = Int64(size.width)
        let height = Int64(size.height)
        guard width > 0, height > 0, width <= Int64.max / height else { return nil }
        let pixels = width * height
        guard pixels <= Int64.max / 4 else { return nil }
        return pixels * 4
    }

    func canRenderRaster(at resolution: PrintSheetResolution) -> Bool {
        let size = rasterPixelSize(at: resolution)
        let width = Int64(size.width)
        let height = Int64(size.height)
        return width > 0
            && height > 0
            && width <= Self.maximumRasterPixelCount / height
    }

    static func make(
        photoSizeInches: CGSize,
        settings: PrintSheetSettings
    ) throws -> PrintSheetLayout {
        guard photoSizeInches.width > 0, photoSizeInches.height > 0 else {
            throw PrintSheetError.missingPhysicalSize
        }

        let pageSize = settings.paperSize.orientedSize(for: settings.paperOrientation)
        let availableWidth = pageSize.width - settings.edgeInsetInches * 2
        let availableHeight = pageSize.height - settings.edgeInsetInches * 2
        let columns = Int(floor(
            (availableWidth + settings.gutterInches)
                / (photoSizeInches.width + settings.gutterInches)
        ))
        let rows = Int(floor(
            (availableHeight + settings.gutterInches)
                / (photoSizeInches.height + settings.gutterInches)
        ))

        guard columns > 0, rows > 0 else {
            throw PrintSheetError.photoDoesNotFit
        }

        let usedWidth = CGFloat(columns) * photoSizeInches.width
            + CGFloat(columns - 1) * settings.gutterInches
        let usedHeight = CGFloat(rows) * photoSizeInches.height
            + CGFloat(rows - 1) * settings.gutterInches
        let startX = (pageSize.width - usedWidth) / 2
        let startY = (pageSize.height - usedHeight) / 2

        var rects: [CGRect] = []
        for row in 0..<rows {
            for column in 0..<columns {
                rects.append(CGRect(
                    x: startX + CGFloat(column) * (photoSizeInches.width + settings.gutterInches),
                    y: startY + CGFloat(row) * (photoSizeInches.height + settings.gutterInches),
                    width: photoSizeInches.width,
                    height: photoSizeInches.height
                ))
            }
        }

        return PrintSheetLayout(
            pageSizeInches: pageSize,
            photoSizeInches: photoSizeInches,
            photoRectsInches: rects
        )
    }
}
