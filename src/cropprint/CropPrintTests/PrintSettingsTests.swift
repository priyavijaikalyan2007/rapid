import CoreGraphics
import ImageIO
import XCTest

final class PrintSettingsTests: XCTestCase {
    func testLandscapeRotatesAspectRatio() {
        var settings = PrintSettings()
        settings.preset = .fourBySix
        settings.orientation = .landscape

        XCTAssertEqual(settings.aspectRatio, 1.5, accuracy: 0.001)
    }

    func testOutputSuffixContainsEveryChoice() {
        var settings = PrintSettings()
        settings.preset = .eightByTen
        settings.orientation = .landscape
        settings.paperSize = .letter
        settings.includesMargin = true

        XCTAssertEqual(settings.fileSuffix, "8x10-landscape-letter-margin")
    }

    func testLargePhotoDoesNotFitLetterPaper() {
        var settings = PrintSettings()
        settings.preset = .twentyFourByThirtySix
        settings.paperSize = .letter

        XCTAssertFalse(settings.fitsPaper)
    }

    func testInsideMarginDoesNotChangeRequiredPaperSize() {
        var settings = PrintSettings()
        settings.preset = .fourBySix
        settings.paperSize = .postcard
        settings.includesMargin = true

        XCTAssertTrue(settings.fitsPaper)
    }

    func testInstagramStoryUsesNineBySixteenRatio() {
        var settings = PrintSettings()
        settings.preset = .instagramStory

        XCTAssertEqual(settings.aspectRatio, 9.0 / 16.0, accuracy: 0.001)
        XCTAssertEqual(settings.outputPixels, CGSize(width: 1080, height: 1920))
    }

    func testDigitalPresetIgnoresPrintOrientation() {
        var settings = PrintSettings()
        settings.preset = .macBookPro14
        settings.orientation = .portrait
        let portraitSetting = settings.aspectRatio
        settings.orientation = .landscape

        XCTAssertEqual(settings.aspectRatio, portraitSetting, accuracy: 0.001)
        XCTAssertEqual(settings.outputPixels, CGSize(width: 3024, height: 1964))
    }

    func testPhoneWallpaperPixelSizes() {
        XCTAssertEqual(CropPreset.iPhone14Pro.targetPixels, CGSize(width: 1179, height: 2556))
        XCTAssertEqual(CropPreset.iPhone17Pro.targetPixels, CGSize(width: 1206, height: 2622))
        XCTAssertEqual(CropPreset.iPhone16eHome.targetPixels, CGSize(width: 1170, height: 2532))
        XCTAssertEqual(CropPreset.iPhone16eLock.targetPixels, CGSize(width: 1170, height: 2532))
    }

    func testMacBookWallpaperPixelSizes() {
        XCTAssertEqual(CropPreset.macBookAir13.targetPixels, CGSize(width: 2560, height: 1664))
        XCTAssertEqual(CropPreset.macBookAir15.targetPixels, CGSize(width: 2880, height: 1864))
        XCTAssertEqual(CropPreset.macBookPro13.targetPixels, CGSize(width: 2560, height: 1600))
        XCTAssertEqual(CropPreset.macBookPro14.targetPixels, CGSize(width: 3024, height: 1964))
        XCTAssertEqual(CropPreset.macBookPro16.targetPixels, CGSize(width: 3456, height: 2234))
    }

    func testPassportPresetRatios() {
        XCTAssertEqual(CropPreset.passportIndia.aspectRatio(for: .portrait), 35.0 / 45.0, accuracy: 0.001)
        XCTAssertEqual(CropPreset.passportUS.aspectRatio(for: .portrait), 1.0, accuracy: 0.001)
        XCTAssertEqual(CropPreset.passportCanada.aspectRatio(for: .portrait), 50.0 / 70.0, accuracy: 0.001)
        XCTAssertEqual(CropPreset.passportChina.aspectRatio(for: .portrait), 33.0 / 48.0, accuracy: 0.001)
    }

    func testDigitalPassportPixelSizes() {
        XCTAssertEqual(CropPreset.passportSingaporeDigital.targetPixels, CGSize(width: 400, height: 514))
        XCTAssertEqual(CropPreset.passportNewZealandDigital.targetPixels, CGSize(width: 900, height: 1200))
    }

    func testSingaporeAndNewZealandPrintPassportSizes() {
        let expectedSize = CGSize(width: 35.0 / 25.4, height: 45.0 / 25.4)

        XCTAssertEqual(CropPreset.passportSingaporePrint.physicalInches, expectedSize)
        XCTAssertEqual(CropPreset.passportNewZealandPrint.physicalInches, expectedSize)
        XCTAssertNil(CropPreset.passportSingaporeDigital.physicalInches)
        XCTAssertNil(CropPreset.passportNewZealandDigital.physicalInches)
    }

    func testMonitorPixelSizes() {
        XCTAssertEqual(CropPreset.monitorVGA.targetPixels, CGSize(width: 640, height: 480))
        XCTAssertEqual(CropPreset.monitorFullHD.targetPixels, CGSize(width: 1920, height: 1080))
        XCTAssertEqual(CropPreset.monitorQHD.targetPixels, CGSize(width: 2560, height: 1440))
        XCTAssertEqual(CropPreset.monitorUHD4K.targetPixels, CGSize(width: 3840, height: 2160))
        XCTAssertEqual(CropPreset.monitor5K.targetPixels, CGSize(width: 5120, height: 2880))
        XCTAssertEqual(CropPreset.monitor6K.targetPixels, CGSize(width: 6016, height: 3384))
        XCTAssertEqual(CropPreset.monitorUHD8K.targetPixels, CGSize(width: 7680, height: 4320))
    }

    func testMonitorOrientationRotatesPixelsAndSuffix() {
        var settings = PrintSettings()
        settings.preset = .monitorFullHD
        settings.orientation = .portrait

        XCTAssertEqual(settings.outputPixels, CGSize(width: 1080, height: 1920))
        XCTAssertEqual(settings.fileSuffix, "monitor-full-hd-1920x1080-portrait")

        settings.orientation = .landscape

        XCTAssertEqual(settings.outputPixels, CGSize(width: 1920, height: 1080))
        XCTAssertEqual(settings.fileSuffix, "monitor-full-hd-1920x1080-landscape")
    }

    func testUSPassportCopiesOnFiveBySevenPaper() throws {
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .fiveBySeven
        sheetSettings.paperOrientation = .portrait

        let layout = try PrintSheetLayout.make(
            photoSizeInches: CropPreset.passportUS.dimensions(for: .portrait),
            settings: sheetSettings
        )

        XCTAssertEqual(layout.copyCount, 6)
    }

    func testIndiaPassportCopiesOnFourBySixPaper() throws {
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .postcard
        sheetSettings.paperOrientation = .portrait

        let layout = try PrintSheetLayout.make(
            photoSizeInches: CropPreset.passportIndia.dimensions(for: .portrait),
            settings: sheetSettings
        )

        XCTAssertEqual(layout.copyCount, 6)
    }

    func testUSPassportCopiesOnA4Paper() throws {
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .a4
        sheetSettings.paperOrientation = .portrait

        let layout = try PrintSheetLayout.make(
            photoSizeInches: CropPreset.passportUS.dimensions(for: .portrait),
            settings: sheetSettings
        )

        XCTAssertEqual(layout.copyCount, 15)
    }

    func testOversizedPhotoDoesNotFitPrintSheet() {
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .postcard

        XCTAssertThrowsError(
            try PrintSheetLayout.make(
                photoSizeInches: CropPreset.eightByTen.dimensions(for: .portrait),
                settings: sheetSettings
            )
        )
    }

    func testPrintSheetRasterAndFileDimensions() throws {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let sourceContext = try XCTUnwrap(CGContext(
            data: nil,
            width: 10,
            height: 10,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        sourceContext.setFillColor(CGColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1))
        sourceContext.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        let sourceImage = try XCTUnwrap(sourceContext.makeImage())

        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .fiveBySeven
        sheetSettings.paperOrientation = .portrait
        sheetSettings.resolution = .ppi300
        let layout = try PrintSheetLayout.make(
            photoSizeInches: CropPreset.passportUS.dimensions(for: .portrait),
            settings: sheetSettings
        )

        let raster = try PrintSheetRenderer.rasterImage(
            photo: sourceImage,
            layout: layout,
            settings: sheetSettings
        )
        XCTAssertEqual(raster.width, 1500)
        XCTAssertEqual(raster.height, 2100)

        let jpeg = try PrintSheetRenderer.jpegData(for: raster, resolution: .ppi300)
        let imageSource = try XCTUnwrap(CGImageSourceCreateWithData(jpeg as CFData, nil))
        let properties = try XCTUnwrap(
            CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
        )
        XCTAssertEqual(properties[kCGImagePropertyDPIWidth] as? Int, 300)
        XCTAssertEqual(properties[kCGImagePropertyDPIHeight] as? Int, 300)

        let pdf = try PrintSheetRenderer.pdfData(
            photo: sourceImage,
            layout: layout,
            settings: sheetSettings
        )
        let provider = try XCTUnwrap(CGDataProvider(data: pdf as CFData))
        let document = try XCTUnwrap(CGPDFDocument(provider))
        let page = try XCTUnwrap(document.page(at: 1))
        let mediaBox = page.getBoxRect(.mediaBox)
        XCTAssertEqual(mediaBox.width, 360, accuracy: 0.01)
        XCTAssertEqual(mediaBox.height, 504, accuracy: 0.01)
    }

    func testLargeSheetRejectsUnsafeRasterSize() throws {
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .twentyFourByThirtySix
        let layout = try PrintSheetLayout.make(
            photoSizeInches: CropPreset.fourBySix.dimensions(for: .portrait),
            settings: sheetSettings
        )

        XCTAssertTrue(layout.canRenderRaster(at: .ppi300))
        XCTAssertFalse(layout.canRenderRaster(at: .ppi600))
    }

    func testPrintAndPrinterResolutionChoices() {
        XCTAssertEqual(
            PrintSheetResolution.allCases.map(\.rawValue),
            [72, 96, 150, 200, 240, 300, 360, 600, 720, 1200]
        )
        XCTAssertEqual(
            PrinterResolution.allCases.map(\.rawValue),
            [300, 600, 720, 1200, 1440, 2400, 4800]
        )
    }

    func testRasterSizeAndMemoryEstimate() throws {
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .fiveBySeven
        let layout = try PrintSheetLayout.make(
            photoSizeInches: CropPreset.passportUS.dimensions(for: .portrait),
            settings: sheetSettings
        )

        XCTAssertEqual(layout.rasterPixelSize(at: .ppi300), CGSize(width: 1500, height: 2100))
        XCTAssertEqual(layout.estimatedRasterBytes(at: .ppi300), 12_600_000)
        XCTAssertTrue(layout.canRenderRaster(at: .ppi1200))
    }
}
