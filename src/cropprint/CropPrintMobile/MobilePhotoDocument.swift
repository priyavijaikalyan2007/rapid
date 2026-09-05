import Photos
import SwiftUI
import UIKit

struct MobilePhoto {
    let image: UIImage
    let cgImage: CGImage

    var pixelSize: CGSize {
        CGSize(width: cgImage.width, height: cgImage.height)
    }
}

enum MobilePhotoError: LocalizedError {
    case unreadableImage
    case invalidCrop
    case renderFailed
    case photosAccessDenied

    var errorDescription: String? {
        switch self {
        case .unreadableImage: "The app could not read this image."
        case .invalidCrop: "The crop area is not valid."
        case .renderFailed: "The app could not create the cropped image."
        case .photosAccessDenied: "Allow CropPrint to add photos in Settings."
        }
    }
}

@MainActor
final class MobilePhotoDocument: ObservableObject {
    private var personMask: CGImage?
    private var processingTask: Task<Void, Never>?

    @Published var photo: MobilePhoto?
    @Published var settings = PrintSettings()
    @Published var printSheetSettings = PrintSheetSettings()
    @Published var decoration = DecorationSettings()
    @Published var adjustments = PhotoAdjustmentSettings()
    @Published private(set) var processedImage: CGImage?
    @Published private(set) var isProcessingPhoto = false
    @Published var normalizedCrop = CGRect.zero
    @Published var message = "Choose a photo to begin."
    @Published var showsError = false

    init() {
#if DEBUG
        loadAppStoreScreenshotSampleIfNeeded()
#endif
    }

    var canSave: Bool {
        photo != nil && normalizedCrop.width > 0 && normalizedCrop.height > 0
            && !isProcessingPhoto
    }

    var canCreatePrintSheet: Bool {
        canSave && settings.preset.physicalInches != nil
    }

    var croppedPreviewImage: CGImage? {
        guard let photo else { return nil }
        let pixelRect = CropGeometry.pixelCrop(
            from: normalizedCrop,
            imageSize: photo.pixelSize
        )
        return (processedImage ?? photo.cgImage).cropping(to: pixelRect)
    }

    var displayImage: CGImage? {
        guard let photo else { return nil }
        return processedImage ?? photo.cgImage
    }

    func load(data: Data) {
        guard let sourceImage = UIImage(data: data),
              let normalized = sourceImage.normalizedForCropping(),
              let cgImage = normalized.cgImage else {
            report(MobilePhotoError.unreadableImage)
            return
        }

        photo = MobilePhoto(image: normalized, cgImage: cgImage)
        resetPhotoProcessing()
        resetCrop()
        message = "Loaded \(cgImage.width) x \(cgImage.height) pixels."
        showsError = false
    }

    func resetCrop() {
        guard let photo else { return }
        let crop = CropGeometry.centeredCrop(in: photo.pixelSize, aspectRatio: settings.aspectRatio)
        normalizedCrop = CGRect(
            x: crop.minX / photo.pixelSize.width,
            y: crop.minY / photo.pixelSize.height,
            width: crop.width / photo.pixelSize.width,
            height: crop.height / photo.pixelSize.height
        )
    }

    func updatePhotoProcessing() {
        guard let photo else { return }
        processingTask?.cancel()

        if adjustments.isDefault {
            processedImage = nil
            isProcessingPhoto = false
            message = "Photo edits reset."
            showsError = false
            return
        }

        let source = photo.cgImage
        let requestedSettings = adjustments
        let cachedMask = personMask
        isProcessingPhoto = true
        message = "Applying local photo edits…"
        showsError = false

        processingTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }
            let result = await Task.detached(priority: .userInitiated) {
                Result {
                    try LocalPhotoProcessor.render(
                        source: source,
                        settings: requestedSettings,
                        cachedPersonMask: cachedMask
                    )
                }
            }.value
            guard let self, !Task.isCancelled, self.adjustments == requestedSettings else {
                return
            }
            switch result {
            case .success(let output):
                self.processedImage = output.image
                if let mask = output.personMask {
                    self.personMask = mask
                }
                self.isProcessingPhoto = false
                self.message = "Photo edits preview updated locally."
                self.showsError = false
            case .failure(let error):
                self.isProcessingPhoto = false
                self.report(error)
            }
        }
    }

    func saveToPhotos() {
        guard let photo else { return }
        do {
            let output = try MobileImageExporter.render(
                photo: photo,
                sourceImage: processedImage ?? photo.cgImage,
                normalizedCrop: normalizedCrop,
                settings: settings,
                decoration: decoration,
                remoteFrameURL: decoration.remoteFrameID.flatMap {
                    ResourceLibrary.shared.cachedFileURL(for: $0)
                }
            )
            let image = UIImage(cgImage: output)
            Task {
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    report(MobilePhotoError.photosAccessDenied)
                    return
                }
                do {
                    try await addToPhotoLibrary(image)
                    message = "Saved the cropped image to Photos."
                    showsError = false
                } catch {
                    report(error)
                }
            }
        } catch {
            report(error)
        }
    }

    func createPrintSheetInPhotos() {
        guard let photo else { return }
        do {
            let output = try MobileImageExporter.renderPrintSheet(
                photo: photo,
                sourceImage: processedImage ?? photo.cgImage,
                normalizedCrop: normalizedCrop,
                settings: settings,
                decoration: decoration,
                remoteFrameURL: decoration.remoteFrameID.flatMap {
                    ResourceLibrary.shared.cachedFileURL(for: $0)
                },
                sheetSettings: printSheetSettings
            )
            let image = UIImage(cgImage: output.image)
            Task {
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    report(MobilePhotoError.photosAccessDenied)
                    return
                }
                do {
                    try await addToPhotoLibrary(image)
                    message = "Saved a \(output.copyCount)-copy print sheet to Photos."
                    showsError = false
                } catch {
                    report(error)
                }
            }
        } catch {
            report(error)
        }
    }

    private func addToPhotoLibrary(_ image: UIImage) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: MobilePhotoError.renderFailed)
                }
            }
        }
    }

    private func report(_ error: Error) {
        message = error.localizedDescription
        showsError = true
    }

    private func resetPhotoProcessing() {
        processingTask?.cancel()
        adjustments = PhotoAdjustmentSettings()
        processedImage = nil
        personMask = nil
        isProcessingPhoto = false
    }

#if DEBUG
    private func loadAppStoreScreenshotSampleIfNeeded() {
        guard let scenario = AppStoreScreenshotScenario.current,
              let sampleURL = AppStoreScreenshotScenario.samplePhotoURL,
              let data = try? Data(contentsOf: sampleURL) else {
            return
        }

        load(data: data)
        configureAppStoreScreenshot(for: scenario)
    }

    private func configureAppStoreScreenshot(for scenario: AppStoreScreenshotScenario) {
        switch scenario {
        case .passport, .printSheet, .trueSize:
            settings.preset = .passportUS
            settings.paperSize = .fiveBySeven
            printSheetSettings.paperSize = .fiveBySeven
            printSheetSettings.printerResolution = .dpi1200
        case .decorate:
            settings.preset = .instagramPortrait
            decoration.text = "Make it yours"
            decoration.textColor = .white
            decoration.textStyle = .shadow
            decoration.textRotation = -4
            decoration.textY = 0.78
            decoration.frameStyle = .double
            decoration.frameColor = .gold
        case .crop, .resources, .preview:
            settings.preset = .fiveBySeven
            settings.orientation = .landscape
            settings.paperSize = .letter
        }

        resetCrop()
        if scenario == .crop || scenario == .preview {
            let crop = normalizedCrop
            normalizedCrop = crop.insetBy(
                dx: crop.width * 0.08,
                dy: crop.height * 0.08
            ).offsetBy(dx: -0.04, dy: 0.02)
        }
    }
#endif
}

private extension UIImage {
    func normalizedForCropping() -> UIImage? {
        guard let cgImage else { return nil }
        guard imageOrientation != .up else { return self }
        let swapsDimensions = imageOrientation == .left || imageOrientation == .leftMirrored
            || imageOrientation == .right || imageOrientation == .rightMirrored
        let outputSize = swapsDimensions
            ? CGSize(width: cgImage.height, height: cgImage.width)
            : CGSize(width: cgImage.width, height: cgImage.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: outputSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: outputSize))
        }
    }
}
