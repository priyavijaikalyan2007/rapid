// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: fbc3c78d-4a71-4bf7-9504-13dd1b816a48
// Created: 2026
// COMPONENT: LocalPhotoProcessor
// PURPOSE: Applies on-device photo adjustments and person segmentation.
// RELATES: [[CropPrint]]
// FLOW: Native application -> LocalPhotoProcessor -> local result.

import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import Vision

/// Applies on-device photo adjustments and person segmentation.
enum LocalPhotoProcessor
{
    /// Reuses the thread-safe Core Image context while disabling intermediate image retention.
    private static let context = CIContext(options: [
        .cacheIntermediates: false
    ])

    /// Applies local adjustments and returns pixels plus the reusable person mask. Cancellation throws.
    static func render(
        source: CGImage,
        settings: PhotoAdjustmentSettings,
        cachedPersonMask: CGImage?
    ) throws -> PhotoProcessingResult
    {
        try Task.checkCancellation()
        let extent = CGRect(x: 0, y: 0, width: source.width, height: source.height)
        let personMask = try resolvedPersonMask(source, settings: settings, cached: cachedPersonMask)
        let transform = settings.angle == 0 ? CGAffineTransform.identity
            : coverTransform(for: extent, radians: settings.angle * .pi / 180)
        let adjusted = applyToneAdjustments(to: CIImage(cgImage: source), settings: settings)
            .transformed(by: transform).cropped(to: extent)
        let mask = personMask.map
        {
            CIImage(cgImage: $0).transformed(by: transform).cropped(to: extent)
        }
        let image = replacingBackground(in: adjusted, mask: mask, color: settings.background.color, extent: extent)
        try Task.checkCancellation()
        guard let rendered = context.createCGImage(image, from: extent)
        else
        {
            throw PhotoProcessingError.renderFailed
        }
        try Task.checkCancellation()
        return PhotoProcessingResult(image: rendered, personMask: personMask)
    }

    /// Uses on-device Vision segmentation without sending image content to a server.
    private static func makePersonMask(for source: CGImage) throws -> CGImage
    {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        let handler = VNImageRequestHandler(cgImage: source, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first
        else
        {
            throw PhotoProcessingError.noPersonFound
        }
        let lowResolutionMask = CIImage(cvPixelBuffer: observation.pixelBuffer)
        let scale = CGAffineTransform(
            scaleX: CGFloat(source.width) / lowResolutionMask.extent.width,
            y: CGFloat(source.height) / lowResolutionMask.extent.height
        )
        let scaledMask = lowResolutionMask.transformed(by: scale).cropped(
            to: CGRect(x: 0, y: 0, width: source.width, height: source.height)
        )
        guard let mask = context.createCGImage(scaledMask, from: scaledMask.extent)
        else
        {
            throw PhotoProcessingError.renderFailed
        }
        return mask
    }

    /// Applies the selected local Core Image tone and detail filters.
    private static func applyToneAdjustments(to source: CIImage, settings: PhotoAdjustmentSettings) -> CIImage
    {
        let exposed = exposureAdjusted(source, amount: settings.exposure)
        let colored = colorAdjusted(exposed, settings: settings)
        let toned = toneCurveAdjusted(colored, settings: settings)
        return detailAdjusted(toned, settings: settings)
    }

    /// Computes a centered rotation that keeps the resulting image edges covered.
    private static func coverTransform(for extent: CGRect, radians: CGFloat) -> CGAffineTransform
    {
        let cosine = abs(cos(radians))
        let sine = abs(sin(radians))
        let rotatedWidth = extent.width * cosine + extent.height * sine
        let rotatedHeight = extent.width * sine + extent.height * cosine
        let scale = max(rotatedWidth / extent.width, rotatedHeight / extent.height)
        let center = CGPoint(x: extent.midX, y: extent.midY)

        return CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: radians)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -center.x, y: -center.y)
    }

    /// Reuses the person mask without running segmentation for ordinary tone adjustments.
    private static func resolvedPersonMask(
        _ source: CGImage, settings: PhotoAdjustmentSettings, cached: CGImage?
    ) throws -> CGImage?
    {
        guard settings.background != .original
        else
        {
            return cached
        }
        try Task.checkCancellation()
        return try cached ?? makePersonMask(for: source)
    }

    /// Blends the chosen solid background behind the person while retaining the original extent.
    private static func replacingBackground(
        in image: CIImage, mask: CIImage?, color: CIColor?, extent: CGRect
    ) -> CIImage
    {
        guard let color, let mask
        else
        {
            return image
        }
        return image.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: CIImage(color: color).cropped(to: extent),
            kCIInputMaskImageKey: mask
        ])
    }

    /// Applies exposure only when the user changes its neutral value.
    private static func exposureAdjusted(_ image: CIImage, amount: Double) -> CIImage
    {
        guard amount != 0
        else
        {
            return image
        }
        return image.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: amount])
    }

    /// Applies contrast and saturation together so the neutral path adds no filter.
    private static func colorAdjusted(_ image: CIImage, settings: PhotoAdjustmentSettings) -> CIImage
    {
        guard settings.contrast != 1 || settings.saturation != 1
        else
        {
            return image
        }
        return image.applyingFilter("CIColorControls", parameters: [
            kCIInputContrastKey: settings.contrast, kCIInputSaturationKey: settings.saturation
        ])
    }

    /// Keeps the tone curve monotonic while adjusting highlight and shadow control points.
    private static func toneCurveAdjusted(_ image: CIImage, settings: PhotoAdjustmentSettings) -> CIImage
    {
        guard settings.highlights != 0 || settings.shadows != 0
        else
        {
            return image
        }
        let shadowPoint = min(0.48, max(0.02, 0.25 + settings.shadows * 0.2))
        let highlightPoint = min(0.98, max(0.52, 0.75 + settings.highlights * 0.2))
        return image.applyingFilter("CIToneCurve", parameters: [
            "inputPoint0": CIVector(x: 0, y: 0), "inputPoint1": CIVector(x: 0.25, y: shadowPoint),
            "inputPoint2": CIVector(x: 0.5, y: 0.5), "inputPoint3": CIVector(x: 0.75, y: highlightPoint),
            "inputPoint4": CIVector(x: 1, y: 1)
        ])
    }

    /// Applies hue and sharpness without changing the source dimensions.
    private static func detailAdjusted(_ source: CIImage, settings: PhotoAdjustmentSettings) -> CIImage
    {
        var image = source
        if settings.hue != 0
        {
            image = image.applyingFilter("CIHueAdjust", parameters: [kCIInputAngleKey: settings.hue * .pi / 180])
        }
        if settings.sharpness != 0
        {
            image = image.applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: settings.sharpness])
        }
        return image
    }
}
