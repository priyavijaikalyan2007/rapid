import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import Vision

enum ReplacementBackground: String, CaseIterable, Identifiable {
    case original = "Keep original"
    case white = "White"
    case lightGray = "Light gray"
    case lightBlue = "Light blue"

    var id: Self { self }

    fileprivate var color: CIColor? {
        switch self {
        case .original: nil
        case .white: CIColor(red: 1, green: 1, blue: 1)
        case .lightGray: CIColor(red: 0.9, green: 0.9, blue: 0.9)
        case .lightBlue: CIColor(red: 0.78, green: 0.88, blue: 0.98)
        }
    }
}

struct PhotoAdjustmentSettings: Equatable {
    var exposure: Double = 0
    var contrast: Double = 1
    var highlights: Double = 0
    var shadows: Double = 0
    var saturation: Double = 1
    var hue: Double = 0
    var sharpness: Double = 0
    var angle: Double = 0
    var background: ReplacementBackground = .original

    var isDefault: Bool { self == PhotoAdjustmentSettings() }

    var hasToneChanges: Bool {
        exposure != 0 || contrast != 1 || highlights != 0 || shadows != 0
            || saturation != 1 || hue != 0 || sharpness != 0 || angle != 0
    }
}

struct PhotoProcessingResult {
    let image: CGImage
    let personMask: CGImage?
}

enum PhotoProcessingError: LocalizedError {
    case noPersonFound
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .noPersonFound:
            "The app could not find a person to separate from the background."
        case .renderFailed:
            "The app could not apply the photo edits."
        }
    }
}

enum LocalPhotoProcessor {
    private static let context = CIContext(options: [
        .cacheIntermediates: false
    ])

    static func render(
        source: CGImage,
        settings: PhotoAdjustmentSettings,
        cachedPersonMask: CGImage?
    ) throws -> PhotoProcessingResult {
        let sourceExtent = CGRect(x: 0, y: 0, width: source.width, height: source.height)
        var image = CIImage(cgImage: source)
        var maskImage: CIImage?
        var outputMask = cachedPersonMask

        if settings.background != .original {
            if outputMask == nil {
                outputMask = try makePersonMask(for: source)
            }
            if let outputMask {
                maskImage = CIImage(cgImage: outputMask)
            }
        }

        image = applyToneAdjustments(to: image, settings: settings)

        if settings.angle != 0 {
            let transform = coverTransform(
                for: sourceExtent,
                radians: settings.angle * .pi / 180
            )
            image = image.transformed(by: transform).cropped(to: sourceExtent)
            maskImage = maskImage?.transformed(by: transform).cropped(to: sourceExtent)
        }

        if let backgroundColor = settings.background.color,
           let maskImage {
            let background = CIImage(color: backgroundColor).cropped(to: sourceExtent)
            image = image.applyingFilter(
                "CIBlendWithMask",
                parameters: [
                    kCIInputBackgroundImageKey: background,
                    kCIInputMaskImageKey: maskImage
                ]
            )
        }

        guard let rendered = context.createCGImage(image, from: sourceExtent) else {
            throw PhotoProcessingError.renderFailed
        }
        return PhotoProcessingResult(image: rendered, personMask: outputMask)
    }

    private static func makePersonMask(for source: CGImage) throws -> CGImage {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        let handler = VNImageRequestHandler(cgImage: source, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else {
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
        guard let mask = context.createCGImage(scaledMask, from: scaledMask.extent) else {
            throw PhotoProcessingError.renderFailed
        }
        return mask
    }

    private static func applyToneAdjustments(
        to source: CIImage,
        settings: PhotoAdjustmentSettings
    ) -> CIImage {
        var image = source
        if settings.exposure != 0 {
            image = image.applyingFilter(
                "CIExposureAdjust",
                parameters: [kCIInputEVKey: settings.exposure]
            )
        }
        if settings.contrast != 1 || settings.saturation != 1 {
            image = image.applyingFilter(
                "CIColorControls",
                parameters: [
                    kCIInputContrastKey: settings.contrast,
                    kCIInputSaturationKey: settings.saturation
                ]
            )
        }
        if settings.highlights != 0 || settings.shadows != 0 {
            let shadowPoint = min(0.48, max(0.02, 0.25 + settings.shadows * 0.2))
            let highlightPoint = min(0.98, max(0.52, 0.75 + settings.highlights * 0.2))
            image = image.applyingFilter(
                "CIToneCurve",
                parameters: [
                    "inputPoint0": CIVector(x: 0, y: 0),
                    "inputPoint1": CIVector(x: 0.25, y: shadowPoint),
                    "inputPoint2": CIVector(x: 0.5, y: 0.5),
                    "inputPoint3": CIVector(x: 0.75, y: highlightPoint),
                    "inputPoint4": CIVector(x: 1, y: 1)
                ]
            )
        }
        if settings.hue != 0 {
            image = image.applyingFilter(
                "CIHueAdjust",
                parameters: [kCIInputAngleKey: settings.hue * .pi / 180]
            )
        }
        if settings.sharpness != 0 {
            image = image.applyingFilter(
                "CISharpenLuminance",
                parameters: [kCIInputSharpnessKey: settings.sharpness]
            )
        }
        return image
    }

    private static func coverTransform(for extent: CGRect, radians: CGFloat) -> CGAffineTransform {
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
}
