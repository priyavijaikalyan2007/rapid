import CoreGraphics
import Foundation

enum PrintSheetResolution: Int, CaseIterable, Identifiable {
    case ppi300 = 300
    case ppi600 = 600

    var id: Self { self }
    var title: String { "\(rawValue) PPI" }
}

struct PrintSheetSettings {
    var paperSize: PaperSize = .fiveBySeven
    var paperOrientation: PrintOrientation = .portrait
    var resolution: PrintSheetResolution = .ppi300
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
            "This paper and resolution combination is too large. Select 300 PPI or smaller paper."
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

    func canRenderRaster(at resolution: PrintSheetResolution) -> Bool {
        let pixelsPerInch = Double(resolution.rawValue)
        let width = Int64((Double(pageSizeInches.width) * pixelsPerInch).rounded())
        let height = Int64((Double(pageSizeInches.height) * pixelsPerInch).rounded())
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
