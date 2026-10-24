// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 42c8c6f8-2bd8-48cc-85b0-3f3daaa94305
// Created: 2026
// COMPONENT: PrintSettingsTests
// PURPOSE: Verifies PrintSettings contracts and failure boundaries.
// RELATES: [[CropPrint]]
// FLOW: Test scenario -> contract -> XCTest result.

import CoreGraphics
import ImageIO
import XCTest

/// Verifies PrintSettings contracts and failure boundaries.
final class PrintSettingsTests: XCTestCase
{
    /// Verifies every preset has usable catalog metadata.
    func testEveryPresetHasUsableCatalogMetadata()
    {
        for preset in CropPreset.allCases
        {
            XCTAssertFalse(preset.title.isEmpty, preset.rawValue)
            XCTAssertNotNil(preset.fileLabel.range(of: "^[a-z0-9-]+$", options: .regularExpression))
            for orientation in PrintOrientation.allCases
            {
                let size = preset.dimensions(for: orientation)
                XCTAssertTrue(size.width.isFinite && size.height.isFinite && size.width > 0 && size.height > 0)
            }
        }
    }

    /// Verifies print sheet rejects negative insets.
    func testPrintSheetRejectsNegativeInsets()
    {
        var settings = PrintSheetSettings()
        settings.edgeInsetInches = -1
        XCTAssertThrowsError(try PrintSheetLayout.make(
            photoSizeInches: CGSize(width: 1, height: 1), settings: settings
        ))
    }

    /// Verifies print sheet rejects negative gutters.
    func testPrintSheetRejectsNegativeGutters()
    {
        var settings = PrintSheetSettings()
        settings.gutterInches = -0.1
        XCTAssertThrowsError(try PrintSheetLayout.make(
            photoSizeInches: CGSize(width: 1, height: 1), settings: settings
        ))
    }

    /// Verifies landscape rotates aspect ratio.
    func testLandscapeRotatesAspectRatio()
    {
        var settings = PrintSettings()
        settings.preset = .fourBySix
        settings.orientation = .landscape

        XCTAssertEqual(settings.aspectRatio, 1.5, accuracy: 0.001)
    }

    /// Verifies output suffix contains every choice.
    func testOutputSuffixContainsEveryChoice()
    {
        var settings = PrintSettings()
        settings.preset = .eightByTen
        settings.orientation = .landscape
        settings.paperSize = .letter
        settings.includesMargin = true

        XCTAssertEqual(settings.fileSuffix, "8x10-landscape-letter-margin")
    }

    /// Verifies large photo does not fit letter paper.
    func testLargePhotoDoesNotFitLetterPaper()
    {
        var settings = PrintSettings()
        settings.preset = .twentyFourByThirtySix
        settings.paperSize = .letter

        XCTAssertFalse(settings.fitsPaper)
    }

    /// Verifies inside margin does not change required paper size.
    func testInsideMarginDoesNotChangeRequiredPaperSize()
    {
        var settings = PrintSettings()
        settings.preset = .fourBySix
        settings.paperSize = .postcard
        settings.includesMargin = true

        XCTAssertTrue(settings.fitsPaper)
    }

    /// Verifies instagram story uses nine by sixteen ratio.
    func testInstagramStoryUsesNineBySixteenRatio()
    {
        var settings = PrintSettings()
        settings.preset = .instagramStory

        XCTAssertEqual(settings.aspectRatio, 9.0 / 16.0, accuracy: 0.001)
        XCTAssertEqual(settings.outputPixels, CGSize(width: 1080, height: 1920))
    }

    /// Verifies digital preset ignores print orientation.
    func testDigitalPresetIgnoresPrintOrientation()
    {
        var settings = PrintSettings()
        settings.preset = .macBookPro14
        settings.orientation = .portrait
        let portraitSetting = settings.aspectRatio
        settings.orientation = .landscape

        XCTAssertEqual(settings.aspectRatio, portraitSetting, accuracy: 0.001)
        XCTAssertEqual(settings.outputPixels, CGSize(width: 3024, height: 1964))
    }

    /// Verifies phone wallpaper pixel sizes.
    func testPhoneWallpaperPixelSizes()
    {
        XCTAssertEqual(CropPreset.iPhone14Pro.targetPixels, CGSize(width: 1179, height: 2556))
        XCTAssertEqual(CropPreset.iPhone17Pro.targetPixels, CGSize(width: 1206, height: 2622))
        XCTAssertEqual(CropPreset.iPhone16eHome.targetPixels, CGSize(width: 1170, height: 2532))
        XCTAssertEqual(CropPreset.iPhone16eLock.targetPixels, CGSize(width: 1170, height: 2532))
    }

    /// Verifies mac book wallpaper pixel sizes.
    func testMacBookWallpaperPixelSizes()
    {
        XCTAssertEqual(CropPreset.macBookAir13.targetPixels, CGSize(width: 2560, height: 1664))
        XCTAssertEqual(CropPreset.macBookAir15.targetPixels, CGSize(width: 2880, height: 1864))
        XCTAssertEqual(CropPreset.macBookPro13.targetPixels, CGSize(width: 2560, height: 1600))
        XCTAssertEqual(CropPreset.macBookPro14.targetPixels, CGSize(width: 3024, height: 1964))
        XCTAssertEqual(CropPreset.macBookPro16.targetPixels, CGSize(width: 3456, height: 2234))
    }

    /// Verifies passport preset ratios.
    func testPassportPresetRatios()
    {
        XCTAssertEqual(CropPreset.passportIndia.aspectRatio(for: .portrait), 35.0 / 45.0, accuracy: 0.001)
        XCTAssertEqual(CropPreset.passportUS.aspectRatio(for: .portrait), 1.0, accuracy: 0.001)
        XCTAssertEqual(CropPreset.passportCanada.aspectRatio(for: .portrait), 50.0 / 70.0, accuracy: 0.001)
        XCTAssertEqual(CropPreset.passportChina.aspectRatio(for: .portrait), 33.0 / 48.0, accuracy: 0.001)
    }

    /// Verifies digital passport pixel sizes.
    func testDigitalPassportPixelSizes()
    {
        XCTAssertEqual(CropPreset.passportSingaporeDigital.targetPixels, CGSize(width: 400, height: 514))
        XCTAssertEqual(CropPreset.passportNewZealandDigital.targetPixels, CGSize(width: 900, height: 1200))
    }

    /// Verifies singapore and new zealand print passport sizes.
    func testSingaporeAndNewZealandPrintPassportSizes()
    {
        let expectedSize = CGSize(width: 35.0 / 25.4, height: 45.0 / 25.4)

        XCTAssertEqual(CropPreset.passportSingaporePrint.physicalInches, expectedSize)
        XCTAssertEqual(CropPreset.passportNewZealandPrint.physicalInches, expectedSize)
        XCTAssertNil(CropPreset.passportSingaporeDigital.physicalInches)
        XCTAssertNil(CropPreset.passportNewZealandDigital.physicalInches)
    }

    /// Verifies monitor pixel sizes.
    func testMonitorPixelSizes()
    {
        XCTAssertEqual(CropPreset.monitorVGA.targetPixels, CGSize(width: 640, height: 480))
        XCTAssertEqual(CropPreset.monitorFullHD.targetPixels, CGSize(width: 1920, height: 1080))
        XCTAssertEqual(CropPreset.monitorQHD.targetPixels, CGSize(width: 2560, height: 1440))
        XCTAssertEqual(CropPreset.monitorUHD4K.targetPixels, CGSize(width: 3840, height: 2160))
        XCTAssertEqual(CropPreset.monitor5K.targetPixels, CGSize(width: 5120, height: 2880))
        XCTAssertEqual(CropPreset.monitor6K.targetPixels, CGSize(width: 6016, height: 3384))
        XCTAssertEqual(CropPreset.monitorUHD8K.targetPixels, CGSize(width: 7680, height: 4320))
    }

    /// Verifies monitor orientation rotates pixels and suffix.
    func testMonitorOrientationRotatesPixelsAndSuffix()
    {
        var settings = PrintSettings()
        settings.preset = .monitorFullHD
        settings.orientation = .portrait

        XCTAssertEqual(settings.outputPixels, CGSize(width: 1080, height: 1920))
        XCTAssertEqual(settings.fileSuffix, "monitor-full-hd-1920x1080-portrait")

        settings.orientation = .landscape

        XCTAssertEqual(settings.outputPixels, CGSize(width: 1920, height: 1080))
        XCTAssertEqual(settings.fileSuffix, "monitor-full-hd-1920x1080-landscape")
    }

    /// Verifies uspassport copies on five by seven paper.
    func testUSPassportCopiesOnFiveBySevenPaper() throws
    {
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .fiveBySeven
        sheetSettings.paperOrientation = .portrait

        let layout = try PrintSheetLayout.make(
            photoSizeInches: CropPreset.passportUS.dimensions(for: .portrait),
            settings: sheetSettings
        )

        XCTAssertEqual(layout.copyCount, 6)
    }

    /// Verifies india passport copies on four by six paper.
    func testIndiaPassportCopiesOnFourBySixPaper() throws
    {
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .postcard
        sheetSettings.paperOrientation = .portrait

        let layout = try PrintSheetLayout.make(
            photoSizeInches: CropPreset.passportIndia.dimensions(for: .portrait),
            settings: sheetSettings
        )

        XCTAssertEqual(layout.copyCount, 6)
    }

    /// Verifies uspassport copies on a4 paper.
    func testUSPassportCopiesOnA4Paper() throws
    {
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .a4
        sheetSettings.paperOrientation = .portrait

        let layout = try PrintSheetLayout.make(
            photoSizeInches: CropPreset.passportUS.dimensions(for: .portrait),
            settings: sheetSettings
        )

        XCTAssertEqual(layout.copyCount, 15)
    }

    /// Verifies oversized photo does not fit print sheet.
    func testOversizedPhotoDoesNotFitPrintSheet()
    {
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .postcard

        XCTAssertThrowsError(
            try PrintSheetLayout.make(
                photoSizeInches: CropPreset.eightByTen.dimensions(for: .portrait),
                settings: sheetSettings
            )
        )
    }

    /// Verifies print sheet raster and file dimensions.
    func testPrintSheetRasterAndFileDimensions() throws
    {
        let sourceImage = try sampleRaster()

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

        try verifyJPEG(raster)
        try verifyPDF(sourceImage: sourceImage, layout: layout, settings: sheetSettings)
    }

    /// Verifies large sheet rejects unsafe raster size.
    func testLargeSheetRejectsUnsafeRasterSize() throws
    {
        var sheetSettings = PrintSheetSettings()
        sheetSettings.paperSize = .twentyFourByThirtySix
        let layout = try PrintSheetLayout.make(
            photoSizeInches: CropPreset.fourBySix.dimensions(for: .portrait),
            settings: sheetSettings
        )

        XCTAssertTrue(layout.canRenderRaster(at: .ppi300))
        XCTAssertFalse(layout.canRenderRaster(at: .ppi600))
    }

    /// Verifies print and printer resolution choices.
    func testPrintAndPrinterResolutionChoices()
    {
        XCTAssertEqual(
            PrintSheetResolution.allCases.map(\.rawValue),
            [72, 96, 150, 200, 240, 300, 360, 600, 720, 1200]
        )
        XCTAssertEqual(
            PrinterResolution.allCases.map(\.rawValue),
            [300, 600, 720, 1200, 1440, 2400, 4800]
        )
    }

    /// Verifies preset categories contain every preset once.
    func testPresetCategoriesContainEveryPresetOnce()
    {
        let categorizedPresets = PresetCategory.allCases.flatMap(\.presets)

        XCTAssertEqual(categorizedPresets.count, CropPreset.allCases.count)
        XCTAssertEqual(Set(categorizedPresets), Set(CropPreset.allCases))
        XCTAssertTrue(PresetCategory.passport.presets.contains(.passportUS))
        XCTAssertTrue(PresetCategory.monitor.presets.contains(.monitorUHD8K))
    }

    /// Verifies raster size and memory estimate.
    func testRasterSizeAndMemoryEstimate() throws
    {
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

    /// Creates a deterministic source used to inspect encoded dimensions and physical page geometry.
    private func sampleRaster() throws -> CGImage
    {
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
        return try XCTUnwrap(sourceContext.makeImage())
    }

    /// Inspects the actual JPEG density metadata rather than the encoder settings alone.
    private func verifyJPEG(_ raster: CGImage) throws
    {
        let jpeg = try PrintSheetRenderer.jpegData(for: raster, resolution: .ppi300)
        let imageSource = try XCTUnwrap(CGImageSourceCreateWithData(jpeg as CFData, nil))
        let properties = try XCTUnwrap(
            CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
        )
        XCTAssertEqual(properties[kCGImagePropertyDPIWidth] as? Int, 300)
        XCTAssertEqual(properties[kCGImagePropertyDPIHeight] as? Int, 300)
    }

    /// Checks that vector output preserves the selected physical paper size.
    private func verifyPDF(
        sourceImage: CGImage,
        layout: PrintSheetLayout,
        settings sheetSettings: PrintSheetSettings
    ) throws
    {
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
}
