import AppKit
import XCTest

final class DecorationRendererTests: XCTestCase {
    func testClassicFrameChangesEdgesButNotCenter() throws {
        let source = try solidImage(width: 100, height: 80, color: .red)
        var settings = DecorationSettings()
        settings.frameStyle = .classic
        settings.frameColor = .black
        settings.frameWidth = 0.1

        let output = try DecorationRenderer.render(
            image: source,
            settings: settings,
            remoteFrameURL: nil
        )
        let bitmap = NSBitmapImageRep(cgImage: output)

        XCTAssertEqual(output.width, 100)
        XCTAssertEqual(output.height, 80)
        XCTAssertLessThan(bitmap.colorAt(x: 2, y: 2)?.redComponent ?? 1, 0.1)
        XCTAssertGreaterThan(bitmap.colorAt(x: 50, y: 40)?.redComponent ?? 0, 0.9)
    }

    func testTextDecorationPreservesOutputDimensions() throws {
        let source = try solidImage(width: 160, height: 120, color: .white)
        var settings = DecorationSettings()
        settings.text = "CropPrint"
        settings.textStyle = .badge
        settings.textRotation = 25

        let output = try DecorationRenderer.render(
            image: source,
            settings: settings,
            remoteFrameURL: nil
        )

        XCTAssertEqual(output.width, source.width)
        XCTAssertEqual(output.height, source.height)
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
            throw DecorationRenderError.renderFailed
        }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else { throw DecorationRenderError.renderFailed }
        return image
    }
}
