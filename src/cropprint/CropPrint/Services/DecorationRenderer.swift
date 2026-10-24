// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 2482208d-8989-45fe-a048-47dbbf91e159
// Created: 2026
// COMPONENT: DecorationRenderer
// PURPOSE: Renders built-in frames, validated downloaded frames, and local text into bounded images.
// RELATES: [[CropPrint]]
// FLOW: Native application -> DecorationRenderer -> local result.

import CoreGraphics
import CoreText
import Foundation
import ImageIO

/// Renders built-in frames, validated downloaded frames, and local text into bounded images.
enum DecorationRenderer
{
    /// Produces decorated output pixels and throws when validation or rendering fails.
    static func render(
        image: CGImage,
        settings: DecorationSettings,
        remoteFrameURL: URL?
    ) throws -> CGImage
    {
        guard settings.hasDecorations
        else
        {
            return image
        }
        let width = image.width
        let height = image.height
        let canvas = CGRect(x: 0, y: 0, width: width, height: height)

        guard let context = BitmapCanvas.make(size: CGSize(width: width, height: height), alpha: .premultipliedLast)
        else
        {
            throw DecorationRenderError.renderFailed
        }

        context.interpolationQuality = .high
        context.draw(image, in: canvas)
        drawFrame(in: context, canvas: canvas, settings: settings)

        try drawRemoteFrame(remoteFrameURL, in: context, canvas: canvas, settings: settings)

        drawText(in: context, canvas: canvas, settings: settings)
        return try completedImage(from: context)
    }

    /// Draws a built-in frame while restoring the caller graphics state.
    private static func drawFrame(in context: CGContext, canvas: CGRect, settings: DecorationSettings)
    {
        guard settings.frameStyle != .none
        else
        {
            return
        }
        let width = max(1, min(canvas.width, canvas.height) * settings.frameWidth)
        let color = settings.resolvedFrameCGColor.copy(alpha: settings.frameOpacity) ?? settings.resolvedFrameCGColor
        context.saveGState()
        context.setStrokeColor(color)
        context.setFillColor(color)

        drawFrameShape(in: context, canvas: canvas, width: width, settings: settings)
        context.restoreGState()
    }

    /// Measures and draws local text in normalized image coordinates.
    private static func drawText(in context: CGContext, canvas: CGRect, settings: DecorationSettings)
    {
        guard settings.hasText
        else
        {
            return
        }
        let fontSize = max(8, min(canvas.width, canvas.height) * settings.textSize)
        let attributedText = attributedText(settings: settings, fontSize: fontSize)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        let textSize = textSize(
            framesetter: framesetter,
            length: attributedText.length,
            canvas: canvas,
            settings: settings
        )
        let center = CGPoint(x: canvas.width * settings.textX, y: canvas.height * (1 - settings.textY))

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: -settings.textRotation * .pi / 180)

        drawBadge(in: context, textSize: textSize, fontSize: fontSize, settings: settings)

        applyTextShadow(in: context, fontSize: fontSize, settings: settings)
        drawGlyphs(in: context, framesetter: framesetter, length: attributedText.length, textSize: textSize)
        context.restoreGState()
    }

    /// Validates remote frame dimensions before ImageIO decompresses untrusted pixels.
    private static func drawRemoteFrame(
        _ url: URL?,
        in context: CGContext,
        canvas: CGRect,
        settings: DecorationSettings
    ) throws
    {
        guard let remoteFrameURL = url
        else
        {
            return
        }
        try ImageInputLimits.validate(url: remoteFrameURL)
        if let source = CGImageSourceCreateWithURL(remoteFrameURL as CFURL, nil),
           let frame = CGImageSourceCreateImageAtIndex(source, 0, nil)
        {
            context.saveGState()
            context.setAlpha(settings.frameOpacity)
            context.draw(frame, in: canvas)
            context.restoreGState()
        }
    }

    /// Draws the optional text badge behind the CoreText glyphs.
    private static func drawBadge(
        in context: CGContext,
        textSize: CGSize,
        fontSize: CGFloat,
        settings: DecorationSettings
    )
    {
        if settings.textStyle == .badge
        {
            let padding = fontSize * 0.22
            let badge = CGRect(
                x: -textSize.width / 2 - padding,
                y: -textSize.height / 2 - padding,
                width: textSize.width + padding * 2,
                height: textSize.height + padding * 2
            )
            context.setFillColor(CGColor(gray: 0, alpha: 0.58 * settings.textOpacity))
            context.addPath(CGPath(
                roundedRect: badge,
                cornerWidth: fontSize * 0.18,
                cornerHeight: fontSize * 0.18,
                transform: nil
            ))
            context.fillPath()
        }
    }

    /// Resolves font and stroke attributes for local text rendering.
    private static func attributedText(settings: DecorationSettings, fontSize: CGFloat) -> NSAttributedString
    {
        let font = CTFontCreateWithName(settings.fontName as CFString, fontSize, nil)
        let foreground = settings.resolvedTextCGColor.copy(alpha: settings.textOpacity) ?? settings.resolvedTextCGColor
        var attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: foreground
        ]
        if settings.textStyle == .outline
        {
            attributes[kCTStrokeWidthAttributeName] = -3
            attributes[kCTStrokeColorAttributeName] = CGColor(gray: 0, alpha: settings.textOpacity)
        }

        return NSAttributedString(
            string: settings.text,
            attributes: attributes as [NSAttributedString.Key: Any]
        )
    }

    /// Restricts multiline text to the selected image box while preserving its measured height.
    private static func textSize(
        framesetter: CTFramesetter,
        length: Int,
        canvas: CGRect,
        settings: DecorationSettings
    ) -> CGSize
    {
        let maximumSize = CGSize(
            width: canvas.width * settings.textBoxWidth,
            height: canvas.height * 0.9
        )
        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: length),
            nil,
            maximumSize,
            nil
        )
        return CGSize(
            width: max(1, min(maximumSize.width, suggestedSize.width)),
            height: max(1, min(maximumSize.height, suggestedSize.height))
        )
    }

    /// Draws the measured CoreText frame at the transformed text origin.
    private static func drawGlyphs(in context: CGContext, framesetter: CTFramesetter, length: Int, textSize: CGSize)
    {
        let textRect = CGRect(
            x: -textSize.width / 2,
            y: -textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        let path = CGPath(rect: textRect, transform: nil)
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRange(location: 0, length: length),
            path,
            nil
        )
        CTFrameDraw(frame, context)
    }

    /// Draws the selected built-in frame using the caller's saved graphics state.
    private static func drawFrameShape(
        in context: CGContext,
        canvas: CGRect,
        width: CGFloat,
        settings: DecorationSettings
    )
    {
        switch settings.frameStyle
        {
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
            drawRoundedFrame(in: context, canvas: canvas, width: width)
        case .film:
            context.setStrokeColor(CGColor(gray: 0, alpha: settings.frameOpacity))
            context.setLineWidth(width * 2.2)
            context.stroke(canvas.insetBy(dx: width * 1.1, dy: width * 1.1))
        case .polaroid:
            drawPolaroidFrame(in: context, canvas: canvas, width: width)
        }
    }

    /// Draws the rounded built-in border using the current stroke color.
    private static func drawRoundedFrame(in context: CGContext, canvas: CGRect, width: CGFloat)
    {
        context.setLineWidth(width)
        let rect = canvas.insetBy(dx: width / 2, dy: width / 2)
        context.addPath(CGPath(
            roundedRect: rect,
            cornerWidth: width * 2.2,
            cornerHeight: width * 2.2,
            transform: nil
        ))
        context.strokePath()
    }

    /// Returns completed pixels or a recoverable renderer-specific allocation failure.
    private static func completedImage(from context: CGContext) throws -> CGImage
    {
        guard let image = context.makeImage()
        else
        {
            throw DecorationRenderError.renderFailed
        }
        return image
    }

    /// Applies the selected text shadow without changing the measured text box.
    private static func applyTextShadow(in context: CGContext, fontSize: CGFloat, settings: DecorationSettings)
    {
        if settings.textStyle == .shadow
        {
            context.setShadow(
                offset: CGSize(width: fontSize * 0.04, height: -fontSize * 0.04),
                blur: fontSize * 0.08,
                color: CGColor(gray: 0, alpha: 0.8 * settings.textOpacity)
            )
        }
    }

    /// Preserves the wider lower border of the built-in instant-photo frame.
    private static func drawPolaroidFrame(in context: CGContext, canvas: CGRect, width: CGFloat)
    {
        context.fill(CGRect(x: 0, y: 0, width: canvas.width, height: width))
        context.fill(CGRect(x: 0, y: 0, width: width, height: canvas.height))
        context.fill(CGRect(x: canvas.maxX - width, y: 0, width: width, height: canvas.height))
        context.fill(CGRect(x: 0, y: canvas.maxY - width * 2.6, width: canvas.width, height: width * 2.6))
    }
}
