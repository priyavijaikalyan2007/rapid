// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 01c65837-d13c-4e75-b8fe-a04407c74730
// Created: 2026
// COMPONENT: CropGeometry
// PURPOSE: Calculates bounded image selections and drag geometry.
// RELATES: [[CropPrint]]
// FLOW: Native application -> CropGeometry -> local result.

import CoreGraphics

/// Calculates bounded image selections and drag geometry.
enum CropGeometry
{
    /// Returns the largest centered rectangle that has the target aspect ratio.
    static func centeredCrop(in imageSize: CGSize, aspectRatio: CGFloat) -> CGRect
    {
        guard imageSize.width.isFinite, imageSize.height.isFinite, aspectRatio.isFinite,
              imageSize.width > 0, imageSize.height > 0, aspectRatio > 0
        else
        {
            return .zero
        }

        let imageRatio = imageSize.width / imageSize.height
        if imageRatio > aspectRatio
        {
            let width = imageSize.height * aspectRatio
            return CGRect(x: (imageSize.width - width) / 2, y: 0, width: width, height: imageSize.height)
        }

        let height = imageSize.width / aspectRatio
        return CGRect(x: 0, y: (imageSize.height - height) / 2, width: imageSize.width, height: height)
    }

    /// Keeps a rectangle inside the supplied bounds without changing its dimensions.
    static func clamp(_ rect: CGRect, to bounds: CGRect) -> CGRect
    {
        let x = min(max(rect.minX, bounds.minX), bounds.maxX - rect.width)
        let y = min(max(rect.minY, bounds.minY), bounds.maxY - rect.height)
        return CGRect(origin: CGPoint(x: x, y: y), size: rect.size)
    }

    /// Returns the largest centered rectangle that preserves the content aspect ratio.
    static func aspectFit(content: CGSize, in bounds: CGRect) -> CGRect
    {
        guard content.width > 0, content.height > 0
        else
        {
            return .zero
        }
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
    static func pixelCrop(from normalizedCrop: CGRect, imageSize: CGSize) -> CGRect
    {
        guard normalizedCrop.origin.x.isFinite, normalizedCrop.origin.y.isFinite,
              normalizedCrop.width.isFinite, normalizedCrop.height.isFinite,
              imageSize.width.isFinite, imageSize.height.isFinite,
              normalizedCrop.width > 0, normalizedCrop.height > 0,
              imageSize.width > 0, imageSize.height > 0
        else
        {
            return .zero
        }
        let selection = CGRect(
            x: normalizedCrop.minX * imageSize.width,
            y: normalizedCrop.minY * imageSize.height,
            width: normalizedCrop.width * imageSize.width,
            height: normalizedCrop.height * imageSize.height
        ).integral
        let clipped = selection.intersection(CGRect(origin: .zero, size: imageSize))
        return clipped.isNull ? .zero : clipped
    }

    /// Resizes one corner and keeps the opposite corner fixed.
    static func resizedCrop(
        from startRect: CGRect,
        corner: CropCorner,
        normalizedTranslation: CGSize,
        imageSize: CGSize,
        aspectRatio: CGFloat,
        minimumNormalizedHeight: CGFloat
    ) -> CGRect
    {
        guard imageSize.width.isFinite, imageSize.height.isFinite, aspectRatio.isFinite,
              imageSize.width > 0, imageSize.height > 0, aspectRatio > 0
        else
        {
            return startRect
        }
        let ratio = aspectRatio / (imageSize.width / imageSize.height)
        let anchor = corner.anchor(in: startRect)
        let dragged = corner.point(in: startRect)
            .applying(CGAffineTransform(translationX: normalizedTranslation.width, y: normalizedTranslation.height))
        let size = resizedSize(
            corner: corner,
            anchor: anchor,
            dragged: dragged,
            ratio: ratio,
            minimumHeight: minimumNormalizedHeight
        )
        return CGRect(origin: corner.origin(anchor: anchor, size: size), size: size)
    }

    /// Projects a drag onto the aspect-ratio line and constrains it to the image bounds.
    private static func resizedSize(
        corner: CropCorner, anchor: CGPoint, dragged: CGPoint, ratio: CGFloat, minimumHeight: CGFloat
    ) -> CGSize
    {
        let requestedWidth = corner.extendsRight ? dragged.x - anchor.x : anchor.x - dragged.x
        let requestedHeight = corner.extendsDown ? dragged.y - anchor.y : anchor.y - dragged.y
        let projectedHeight = (requestedWidth * ratio + requestedHeight) / (ratio * ratio + 1)
        let maximumWidth = corner.extendsRight ? 1 - anchor.x : anchor.x
        let maximumHeight = corner.extendsDown ? 1 - anchor.y : anchor.y
        let upperBound = min(maximumHeight, maximumWidth / ratio)
        let lowerBound = min(upperBound, max(0.001, minimumHeight))
        let height = min(upperBound, max(lowerBound, projectedHeight))
        return CGSize(width: height * ratio, height: height)
    }
}
