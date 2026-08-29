import CoreGraphics
import CoreText
import Foundation
import ImageIO

enum DecorationRenderError: LocalizedError {
    case renderFailed

    var errorDescription: String? { "The app could not render the text or frame." }
}

enum DecorationRenderer {
    static func render(
        image: CGImage,
        settings: DecorationSettings,
        remoteFrameURL: URL?
    ) throws -> CGImage {
        guard settings.hasDecorations else { return image }
        let width = image.width
        let height = image.height
        let canvas = CGRect(x: 0, y: 0, width: width, height: height)

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
            throw DecorationRenderError.renderFailed
        }

        context.interpolationQuality = .high
        context.draw(image, in: canvas)
        drawFrame(in: context, canvas: canvas, settings: settings)

        if let remoteFrameURL,
           let source = CGImageSourceCreateWithURL(remoteFrameURL as CFURL, nil),
           let frame = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            context.saveGState()
            context.setAlpha(settings.frameOpacity)
            context.draw(frame, in: canvas)
            context.restoreGState()
        }

        drawText(in: context, canvas: canvas, settings: settings)
        guard let result = context.makeImage() else { throw DecorationRenderError.renderFailed }
        return result
    }

    private static func drawFrame(in context: CGContext, canvas: CGRect, settings: DecorationSettings) {
        guard settings.frameStyle != .none else { return }
        let width = max(1, min(canvas.width, canvas.height) * settings.frameWidth)
        let color = settings.resolvedFrameCGColor.copy(alpha: settings.frameOpacity) ?? settings.resolvedFrameCGColor
        context.saveGState()
        context.setStrokeColor(color)
        context.setFillColor(color)

        switch settings.frameStyle {
        case .none:
            break
        case .classic:
            context.setLineWidth(width)
            context.stroke(canvas.insetBy(dx: width / 2, dy: width / 2))
        case .double:
            context.setLineWidth(width)
            context.stroke(canvas.insetBy(dx: width / 2, dy: width / 2))
            context.setLineWidth(max(1, width * 0.35))
            context.stroke(canvas.insetBy(dx: width * 2, dy: width * 2))
        case .rounded:
            context.setLineWidth(width)
            let rect = canvas.insetBy(dx: width / 2, dy: width / 2)
            context.addPath(CGPath(roundedRect: rect, cornerWidth: width * 2.2, cornerHeight: width * 2.2, transform: nil))
            context.strokePath()
        case .film:
            context.setStrokeColor(CGColor(gray: 0, alpha: settings.frameOpacity))
            context.setLineWidth(width * 2.2)
            context.stroke(canvas.insetBy(dx: width * 1.1, dy: width * 1.1))
        case .polaroid:
            context.fill(CGRect(x: 0, y: 0, width: canvas.width, height: width))
            context.fill(CGRect(x: 0, y: 0, width: width, height: canvas.height))
            context.fill(CGRect(x: canvas.maxX - width, y: 0, width: width, height: canvas.height))
            context.fill(CGRect(x: 0, y: canvas.maxY - width * 2.6, width: canvas.width, height: width * 2.6))
        }
        context.restoreGState()
    }

    private static func drawText(in context: CGContext, canvas: CGRect, settings: DecorationSettings) {
        guard settings.hasText else { return }
        let fontSize = max(8, min(canvas.width, canvas.height) * settings.textSize)
        let font = CTFontCreateWithName(settings.fontName as CFString, fontSize, nil)
        let foreground = settings.resolvedTextCGColor.copy(alpha: settings.textOpacity) ?? settings.resolvedTextCGColor
        var attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: foreground
        ]
        if settings.textStyle == .outline {
            attributes[kCTStrokeWidthAttributeName] = -3
            attributes[kCTStrokeColorAttributeName] = CGColor(gray: 0, alpha: settings.textOpacity)
        }

        let attributedText = NSAttributedString(
            string: settings.text,
            attributes: attributes as [NSAttributedString.Key: Any]
        )
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        let maximumSize = CGSize(
            width: canvas.width * settings.textBoxWidth,
            height: canvas.height * 0.9
        )
        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: attributedText.length),
            nil,
            maximumSize,
            nil
        )
        let textSize = CGSize(
            width: max(1, min(maximumSize.width, suggestedSize.width)),
            height: max(1, min(maximumSize.height, suggestedSize.height))
        )
        let center = CGPoint(x: canvas.width * settings.textX, y: canvas.height * (1 - settings.textY))

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: -settings.textRotation * .pi / 180)

        if settings.textStyle == .badge {
            let padding = fontSize * 0.22
            let badge = CGRect(
                x: -textSize.width / 2 - padding,
                y: -textSize.height / 2 - padding,
                width: textSize.width + padding * 2,
                height: textSize.height + padding * 2
            )
            context.setFillColor(CGColor(gray: 0, alpha: 0.58 * settings.textOpacity))
            context.addPath(CGPath(roundedRect: badge, cornerWidth: fontSize * 0.18, cornerHeight: fontSize * 0.18, transform: nil))
            context.fillPath()
        }

        if settings.textStyle == .shadow {
            context.setShadow(offset: CGSize(width: fontSize * 0.04, height: -fontSize * 0.04), blur: fontSize * 0.08, color: CGColor(gray: 0, alpha: 0.8 * settings.textOpacity))
        }
        let textRect = CGRect(
            x: -textSize.width / 2,
            y: -textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        let path = CGPath(rect: textRect, transform: nil)
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRange(location: 0, length: attributedText.length),
            path,
            nil
        )
        CTFrameDraw(frame, context)
        context.restoreGState()
    }
}
