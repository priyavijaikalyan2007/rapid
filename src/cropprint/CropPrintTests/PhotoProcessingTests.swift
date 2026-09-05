import AppKit
import XCTest

final class PhotoProcessingTests: XCTestCase {
    func testDefaultProcessingPreservesDimensions() throws {
        let source = try solidImage(width: 120, height: 80, color: .systemBlue)
        let result = try LocalPhotoProcessor.render(
            source: source,
            settings: PhotoAdjustmentSettings(),
            cachedPersonMask: nil
        )

        XCTAssertEqual(result.image.width, 120)
        XCTAssertEqual(result.image.height, 80)
        XCTAssertNil(result.personMask)
    }

    func testToneAndAngleProcessingPreservesDimensions() throws {
        let source = try solidImage(width: 120, height: 80, color: .systemBlue)
        var settings = PhotoAdjustmentSettings()
        settings.exposure = 0.5
        settings.contrast = 1.2
        settings.highlights = -0.2
        settings.shadows = 0.3
        settings.saturation = 1.1
        settings.hue = 12
        settings.sharpness = 0.4
        settings.angle = 5

        let result = try LocalPhotoProcessor.render(
            source: source,
            settings: settings,
            cachedPersonMask: nil
        )

        XCTAssertEqual(result.image.width, 120)
        XCTAssertEqual(result.image.height, 80)
        let bitmap = NSBitmapImageRep(cgImage: result.image)
        XCTAssertGreaterThan(bitmap.colorAt(x: 0, y: 0)?.alphaComponent ?? 0, 0.99)
        XCTAssertGreaterThan(bitmap.colorAt(x: 119, y: 79)?.alphaComponent ?? 0, 0.99)
    }

    private func solidImage(width: Int, height: Int, color: NSColor) throws -> CGImage {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw PhotoProcessingError.renderFailed
        }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else {
            throw PhotoProcessingError.renderFailed
        }
        return image
    }
}
