// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: bf4cd9eb-0165-4385-8616-1ef69d12cf6e
// Created: 2026
// COMPONENT: MobilePhotoDocument
// PURPOSE: Owns mobile photo state, local edits, and Photos save requests.
// RELATES: [[CropPrint]]
// FLOW: Native application -> MobilePhotoDocument -> local result.

import Photos
import OSLog
import SwiftUI
import UIKit

/// Owns mobile photo state, local edits, and Photos save requests.
@MainActor
final class MobilePhotoDocument: ObservableObject
{
    /// Writes local operation outcomes without including private content or file paths.
    private static let logger = Logger(subsystem: "us.outcrop.apps.cropprint", category: "MobilePhotoDocument")

    /// Reusable on-device foreground mask for the currently loaded photo.
    private var personMask: CGImage?
    /// The pending preview task, cancelled when a newer edit supersedes it.
    private var processingTask: Task<Void, Never>?

    /// The selected local photo and its decoded source pixels.
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

    /// Initializes mobile document state and optional debug sample selection.
    init()
    {
        #if DEBUG
        loadAppStoreScreenshotSampleIfNeeded()
        #endif
    }

    /// Permits Photos saving only when a photo and valid idle crop are available.
    var canSave: Bool
    {
        photo != nil && normalizedCrop.width > 0 && normalizedCrop.height > 0
            && !isProcessingPhoto
    }

    /// Requires an exportable crop with physical print dimensions.
    var canCreatePrintSheet: Bool
    {
        canSave && settings.preset.physicalInches != nil
    }

    /// Selected source or processed pixels used by the physical-size preview.
    var croppedPreviewImage: CGImage?
    {
        guard let photo
        else
        {
            return nil
        }
        let pixelRect = CropGeometry.pixelCrop(
            from: normalizedCrop,
            imageSize: photo.pixelSize
        )
        return (processedImage ?? photo.cgImage).cropping(to: pixelRect)
    }

    /// Processed preview pixels when available, otherwise the unchanged source pixels.
    var displayImage: CGImage?
    {
        guard let photo
        else
        {
            return nil
        }
        return processedImage ?? photo.cgImage
    }

    /// Validates compressed image size and dimensions before decoding a mobile photo.
    func load(data: Data)
    {
        do
        {
            try ImageInputLimits.validate(data: data)
        }
        catch
        {
            report(error)
            return
        }
        guard let sourceImage = UIImage(data: data),
              let normalized = sourceImage.normalizedForCropping(),
              let cgImage = normalized.cgImage
        else
        {
            report(MobilePhotoError.unreadableImage)
            return
        }

        photo = MobilePhoto(image: normalized, cgImage: cgImage)
        resetPhotoProcessing()
        resetCrop()
        message = "Loaded \(cgImage.width) x \(cgImage.height) pixels."
        showsError = false
    }

    /// Centers the largest valid selection for the current photo and preset.
    func resetCrop()
    {
        guard let photo
        else
        {
            return
        }
        let crop = CropGeometry.centeredCrop(in: photo.pixelSize, aspectRatio: settings.aspectRatio)
        normalizedCrop = CGRect(
            x: crop.minX / photo.pixelSize.width,
            y: crop.minY / photo.pixelSize.height,
            width: crop.width / photo.pixelSize.width,
            height: crop.height / photo.pixelSize.height
        )
    }

    /// Cancels obsolete preview work and schedules the current local edit settings.
    func updatePhotoProcessing()
    {
        guard let photo
        else
        {
            return
        }
        processingTask?.cancel()
        if adjustments.isDefault
        {
            resetPreview()
            return
        }
        let source = photo.cgImage
        let requestedSettings = adjustments
        let cachedMask = personMask
        isProcessingPhoto = true
        message = "Applying local photo edits…"
        showsError = false
        startProcessing(source: source, requestedSettings: requestedSettings, cachedMask: cachedMask)
    }

    /// Renders a cropped result and requests add-only access before saving it to Photos.
    func saveToPhotos()
    {
        guard let photo
        else
        {
            return
        }
        do
        {
            let output = try MobileImageExporter.render(
                photo: photo,
                sourceImage: processedImage ?? photo.cgImage,
                normalizedCrop: normalizedCrop,
                settings: settings,
                decoration: decoration,
                remoteFrameURL: cachedFrameURL
            )
            saveImage(UIImage(cgImage: output), message: "Saved the cropped image to Photos.")
        }
        catch
        {
            report(error)
        }
    }

    /// Renders a physical sheet and saves it through the shared add-only Photos path.
    func createPrintSheetInPhotos()
    {
        guard let photo
        else
        {
            return
        }
        do
        {
            let output = try MobileImageExporter.renderPrintSheet(
                photo: photo,
                sourceImage: processedImage ?? photo.cgImage,
                normalizedCrop: normalizedCrop,
                settings: settings,
                decoration: decoration,
                remoteFrameURL: cachedFrameURL,
                sheetSettings: printSheetSettings
            )
            saveImage(
                UIImage(cgImage: output.image),
                message: "Saved a \(output.copyCount)-copy print sheet to Photos."
            )
        }
        catch
        {
            report(error)
        }
    }

    /// Resumes only after the Photos change transaction succeeds or reports an error.
    private func addToPhotoLibrary(_ image: UIImage) async throws
    {
        try await withCheckedThrowingContinuation
        { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges
            {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if let error
                {
                    continuation.resume(throwing: error)
                }
                else if success
                {
                    continuation.resume(returning: ())
                }
                else
                {
                    continuation.resume(throwing: MobilePhotoError.renderFailed)
                }
            }
        }
    }

    /// Shows the recoverable error in the application without logging private content.
    private func report(_ error: Error)
    {
        Self.logger.error("A local photo operation failed. The recovery message is visible in the application.")
        message = error.localizedDescription
        showsError = true
    }

    /// Cancels pending edits and releases derived pixels and the person mask.
    private func resetPhotoProcessing()
    {
        processingTask?.cancel()
        adjustments = PhotoAdjustmentSettings()
        processedImage = nil
        personMask = nil
        isProcessingPhoto = false
    }

    #if DEBUG
    /// Loads the fixed sample only when a debug capture scenario is requested.
    private func loadAppStoreScreenshotSampleIfNeeded()
    {
        guard let scenario = AppStoreScreenshotScenario.current,
              let sampleURL = AppStoreScreenshotScenario.samplePhotoURL,
              let data = try? Data(contentsOf: sampleURL)
        else
        {
            return
        }

        load(data: data)
        configureAppStoreScreenshot(for: scenario)
    }

    /// Selects repeatable preset and decoration choices for debug capture.
    private func configureAppStoreScreenshot(for scenario: AppStoreScreenshotScenario)
    {
        switch scenario
        {
        case .passport, .printSheet, .trueSize:
            settings.preset = .passportUS
            settings.paperSize = .fiveBySeven
            printSheetSettings.paperSize = .fiveBySeven
            printSheetSettings.printerResolution = .dpi1200
        case .decorate:
            configureDecoratedScreenshot()
        case .crop, .resources, .preview:
            settings.preset = .fiveBySeven
            settings.orientation = .landscape
            settings.paperSize = .letter
        }

        resetCrop()
        if scenario == .crop || scenario == .preview
        {
            let crop = normalizedCrop
            normalizedCrop = crop.insetBy(
                dx: crop.width * 0.08,
                dy: crop.height * 0.08
            ).offsetBy(dx: -0.04, dy: 0.02)
        }
    }
    #endif

    /// Restores source pixels when all edit controls return to their defaults.
    private func resetPreview()
    {
        processedImage = nil
        isProcessingPhoto = false
        message = "Photo edits reset."
        showsError = false
    }

    /// Publishes a current preview and retains its reusable person mask locally.
    private func applyPreview(_ output: PhotoProcessingResult)
    {
        processedImage = output.image
        if let mask = output.personMask
        {
            personMask = mask
        }
        isProcessingPhoto = false
        message = "Photo edits preview updated locally."
        showsError = false
    }

    /// Retains one cancellable task and discards results superseded by a newer edit.
    private func startProcessing(source: CGImage, requestedSettings: PhotoAdjustmentSettings, cachedMask: CGImage?)
    {
        processingTask = Task
        { [weak self] in
            do
            {
                let output = try await PhotoProcessingTask.render(
                    source: source,
                    settings: requestedSettings,
                    cachedMask: cachedMask
                )
                guard let self, !Task.isCancelled, self.adjustments == requestedSettings
                else
                {
                    return
                }
                self.applyPreview(output)
            }
            catch is CancellationError
            {
                return
            }
            catch
            {
                self?.finishProcessingFailure(error)
            }
        }
    }

    /// Prepares the fixed decoration state used only by debug screenshot capture.
    private func configureDecoratedScreenshot()
    {
        #if DEBUG
        settings.preset = .instagramPortrait
        decoration.text = "Make it yours"
        decoration.textColor = .white
        decoration.textStyle = .shadow
        decoration.textRotation = -4
        decoration.textY = 0.78
        decoration.frameStyle = .double
        decoration.frameColor = .gold
        #endif
    }

    /// Requests add-only Photos access and reports success only after the Photos transaction completes.
    private func saveImage(_ image: UIImage, message successMessage: String)
    {
        Task
        {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited
            else
            {
                report(MobilePhotoError.photosAccessDenied)
                return
            }
            do
            {
                try await addToPhotoLibrary(image)
                message = successMessage
                showsError = false
            }
            catch
            {
                report(error)
            }
        }
    }

    /// Resolves only the selected validated catalog frame before export.
    private var cachedFrameURL: URL?
    {
        decoration.remoteFrameID.flatMap
        {
            ResourceLibrary.shared.cachedFileURL(for: $0)
        }
    }

    /// Leaves cancellation silent and reports a genuine failure on the main actor.
    private func finishProcessingFailure(_ error: Error)
    {
        guard !Task.isCancelled
        else
        {
            return
        }
        isProcessingPhoto = false
        report(error)
    }

    /// Adds a recovery action to photo-provider failures without logging the selected content.
    func reportImportFailure(_ error: Error)
    {
        report(error)
        message += " Check that this photo is available in Photos and try again."
    }
}
