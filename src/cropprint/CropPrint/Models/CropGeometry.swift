import CoreGraphics

enum CropCorner: CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

enum CropGeometry {
    /// Returns the largest centered rectangle that has the target aspect ratio.
    static func centeredCrop(in imageSize: CGSize, aspectRatio: CGFloat) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, aspectRatio > 0 else {
            return .zero
        }

        let imageRatio = imageSize.width / imageSize.height
        if imageRatio > aspectRatio {
            let width = imageSize.height * aspectRatio
            return CGRect(x: (imageSize.width - width) / 2, y: 0, width: width, height: imageSize.height)
        }

        let height = imageSize.width / aspectRatio
        return CGRect(x: 0, y: (imageSize.height - height) / 2, width: imageSize.width, height: height)
    }

    static func clamp(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        let x = min(max(rect.minX, bounds.minX), bounds.maxX - rect.width)
        let y = min(max(rect.minY, bounds.minY), bounds.maxY - rect.height)
        return CGRect(origin: CGPoint(x: x, y: y), size: rect.size)
    }

    static func aspectFit(content: CGSize, in bounds: CGRect) -> CGRect {
        guard content.width > 0, content.height > 0 else { return .zero }
        let scale = min(bounds.width / content.width, bounds.height / content.height)
        let size = CGSize(width: content.width * scale, height: content.height * scale)
        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    /// Converts a normalized, top-origin selection to CGImage pixel coordinates.
    static func pixelCrop(from normalizedCrop: CGRect, imageSize: CGSize) -> CGRect {
        CGRect(
            x: normalizedCrop.minX * imageSize.width,
            y: normalizedCrop.minY * imageSize.height,
            width: normalizedCrop.width * imageSize.width,
            height: normalizedCrop.height * imageSize.height
        ).integral
    }

    /// Resizes one corner and keeps the opposite corner fixed.
    static func resizedCrop(
        from startRect: CGRect,
        corner: CropCorner,
        normalizedTranslation: CGSize,
        imageSize: CGSize,
        aspectRatio: CGFloat,
        minimumNormalizedHeight: CGFloat
    ) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, aspectRatio > 0 else {
            return startRect
        }

        let imageRatio = imageSize.width / imageSize.height
        let normalizedRatio = aspectRatio / imageRatio
        let anchor: CGPoint
        let startCorner: CGPoint
        let extendsRight: Bool
        let extendsDown: Bool

        switch corner {
        case .topLeft:
            anchor = CGPoint(x: startRect.maxX, y: startRect.maxY)
            startCorner = CGPoint(x: startRect.minX, y: startRect.minY)
            extendsRight = false
            extendsDown = false
        case .topRight:
            anchor = CGPoint(x: startRect.minX, y: startRect.maxY)
            startCorner = CGPoint(x: startRect.maxX, y: startRect.minY)
            extendsRight = true
            extendsDown = false
        case .bottomLeft:
            anchor = CGPoint(x: startRect.maxX, y: startRect.minY)
            startCorner = CGPoint(x: startRect.minX, y: startRect.maxY)
            extendsRight = false
            extendsDown = true
        case .bottomRight:
            anchor = CGPoint(x: startRect.minX, y: startRect.minY)
            startCorner = CGPoint(x: startRect.maxX, y: startRect.maxY)
            extendsRight = true
            extendsDown = true
        }

        let draggedCorner = CGPoint(
            x: startCorner.x + normalizedTranslation.width,
            y: startCorner.y + normalizedTranslation.height
        )
        let requestedWidth = extendsRight ? draggedCorner.x - anchor.x : anchor.x - draggedCorner.x
        let requestedHeight = extendsDown ? draggedCorner.y - anchor.y : anchor.y - draggedCorner.y

        // Project the pointer movement onto the exact aspect-ratio line.
        let projectedHeight = (requestedWidth * normalizedRatio + requestedHeight)
            / (normalizedRatio * normalizedRatio + 1)
        let maximumWidth = extendsRight ? 1 - anchor.x : anchor.x
        let maximumHeight = extendsDown ? 1 - anchor.y : anchor.y
        let maximumAllowedHeight = min(maximumHeight, maximumWidth / normalizedRatio)
        let minimumHeight = min(maximumAllowedHeight, max(0.001, minimumNormalizedHeight))
        let height = min(maximumAllowedHeight, max(minimumHeight, projectedHeight))
        let width = height * normalizedRatio
        let origin = CGPoint(
            x: extendsRight ? anchor.x : anchor.x - width,
            y: extendsDown ? anchor.y : anchor.y - height
        )
        return CGRect(origin: origin, size: CGSize(width: width, height: height))
    }
}
