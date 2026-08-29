import CoreGraphics
import XCTest

final class CropGeometryTests: XCTestCase {
    func testLandscapeCropUsesFullWidthForTallImage() {
        let crop = CropGeometry.centeredCrop(
            in: CGSize(width: 2000, height: 3000),
            aspectRatio: 3.0 / 2.0
        )

        XCTAssertEqual(crop.width, 2000, accuracy: 0.001)
        XCTAssertEqual(crop.height, 2000 / 1.5, accuracy: 0.001)
        XCTAssertEqual(crop.midY, 1500, accuracy: 0.001)
    }

    func testPortraitCropUsesFullHeightForWideImage() {
        let crop = CropGeometry.centeredCrop(
            in: CGSize(width: 3000, height: 2000),
            aspectRatio: 2.0 / 3.0
        )

        XCTAssertEqual(crop.height, 2000, accuracy: 0.001)
        XCTAssertEqual(crop.width, 2000 * 2 / 3, accuracy: 0.001)
        XCTAssertEqual(crop.midX, 1500, accuracy: 0.001)
    }

    func testClampKeepsCropInsideImage() {
        let crop = CGRect(x: 0.25, y: 0, width: 0.5, height: 1)
        let moved = crop.offsetBy(dx: 0.75, dy: -0.4)
        let result = CropGeometry.clamp(moved, to: CGRect(x: 0, y: 0, width: 1, height: 1))

        XCTAssertEqual(result.minX, 0.5, accuracy: 0.001)
        XCTAssertEqual(result.minY, 0, accuracy: 0.001)
    }

    func testTopSelectionMapsToTopImagePixels() {
        let normalizedCrop = CGRect(x: 0, y: 0, width: 1, height: 0.5)
        let result = CropGeometry.pixelCrop(
            from: normalizedCrop,
            imageSize: CGSize(width: 960, height: 1280)
        )

        XCTAssertEqual(result, CGRect(x: 0, y: 0, width: 960, height: 640))
    }

    func testBottomSelectionMapsToBottomImagePixels() {
        let normalizedCrop = CGRect(x: 0, y: 0.5, width: 1, height: 0.5)
        let result = CropGeometry.pixelCrop(
            from: normalizedCrop,
            imageSize: CGSize(width: 960, height: 1280)
        )

        XCTAssertEqual(result, CGRect(x: 0, y: 640, width: 960, height: 640))
    }

    func testResizeKeepsExactPixelAspectRatio() {
        let start = CGRect(x: 0.1, y: 0.2, width: 0.8, height: 0.6)
        let result = CropGeometry.resizedCrop(
            from: start,
            corner: .topLeft,
            normalizedTranslation: CGSize(width: 0.25, height: 0.1),
            imageSize: CGSize(width: 4000, height: 3000),
            aspectRatio: 3.0 / 2.0,
            minimumNormalizedHeight: 0.02
        )
        let pixelRatio = (result.width * 4000) / (result.height * 3000)

        XCTAssertEqual(pixelRatio, 1.5, accuracy: 0.000001)
        XCTAssertEqual(result.maxX, start.maxX, accuracy: 0.000001)
        XCTAssertEqual(result.maxY, start.maxY, accuracy: 0.000001)
    }

    func testResizeStopsAtImageBoundary() {
        let start = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        let result = CropGeometry.resizedCrop(
            from: start,
            corner: .bottomRight,
            normalizedTranslation: CGSize(width: 2, height: 2),
            imageSize: CGSize(width: 1000, height: 1000),
            aspectRatio: 1,
            minimumNormalizedHeight: 0.02
        )

        XCTAssertEqual(result.minX, 0.25, accuracy: 0.000001)
        XCTAssertEqual(result.minY, 0.25, accuracy: 0.000001)
        XCTAssertEqual(result.maxX, 1, accuracy: 0.000001)
        XCTAssertEqual(result.maxY, 1, accuracy: 0.000001)
    }

    func testResizeHonorsMinimumSize() {
        let start = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
        let result = CropGeometry.resizedCrop(
            from: start,
            corner: .topLeft,
            normalizedTranslation: CGSize(width: 1, height: 1),
            imageSize: CGSize(width: 1000, height: 1000),
            aspectRatio: 1,
            minimumNormalizedHeight: 0.1
        )

        XCTAssertEqual(result.width, 0.1, accuracy: 0.000001)
        XCTAssertEqual(result.height, 0.1, accuracy: 0.000001)
    }
}
