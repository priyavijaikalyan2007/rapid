// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 8f44452e-8d97-4a02-b473-d4030e121610
// Created: 2026
// COMPONENT: PhotoDocument
// PURPOSE: Owns macOS photo state, recent-file access, and export actions.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PhotoDocument -> local result.

import AppKit
import OSLog
import SwiftUI
import UniformTypeIdentifiers

/// Owns macOS photo state, recent-file access, and export actions.
@MainActor
final class PhotoDocument: ObservableObject
{
    /// Writes local operation outcomes without including private content or file paths.
    private static let logger = Logger(subsystem: "us.outcrop.apps.cropprint", category: "PhotoDocument")

    /// Shared legacy recent photos key metadata used by PhotoDocument.
    private static let legacyRecentPhotosKey = "recentPhotoPaths"
    /// Shared recent photo bookmarks key metadata used by PhotoDocument.
    private static let recentPhotoBookmarksKey = "recentPhotoBookmarks"
    /// Shared maximum recent photos metadata used by PhotoDocument.
    private static let maximumRecentPhotos = 10

    /// Bounded security-scoped bookmarks for recent selections.
    private var recentPhotoBookmarks: [Data] = []
    /// URL whose sandbox access remains active while the photo is selected.
    private var activeSecurityScopedURL: URL?
    /// Records whether the current sandbox grant needs a matching stop call.
    private var activeURLNeedsStop = false
    /// Reusable on-device foreground mask for the currently loaded photo.
    private var personMask: CGImage?
    /// The pending preview task, cancelled when a newer edit supersedes it.
    private var processingTask: Task<Void, Never>?

    /// The selected local photo and its decoded source pixels.
    @Published var photo: LoadedPhoto?
    @Published var settings = PrintSettings()
    @Published var printSheetSettings = PrintSheetSettings()
    @Published var decoration = DecorationSettings()
    @Published var adjustments = PhotoAdjustmentSettings()
    @Published private(set) var processedImage: CGImage?
    @Published private(set) var isProcessingPhoto = false
    @Published var normalizedCrop = CGRect.zero
    @Published var message = "Open a photo to begin."
    @Published var showsError = false
    @Published var showsPrintSheetOptions = false
    @Published private(set) var recentPhotoURLs: [URL] = []

    /// Restores recent-file bookmarks and optional debug sample selection.
    init()
    {
        restoreRecentPhotos()
        #if DEBUG
        loadAppStoreScreenshotSampleIfNeeded()
        #endif
    }

    /// Permits export only when a photo and valid idle crop are available.
    var canExport: Bool
    {
        photo != nil && normalizedCrop.width > 0 && normalizedCrop.height > 0
            && !isProcessingPhoto
    }

    /// Requires an exportable crop with physical print dimensions.
    var canCreatePrintSheet: Bool
    {
        canExport && settings.preset.physicalInches != nil
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

    /// Uses the system file picker to obtain access to one selected image.
    func showOpenPanel()
    {
        let panel = NSOpenPanel()
        panel.title = "Open Photo"
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url
        else
        {
            return
        }
        open(url: url)
    }

    /// Validates and loads a selected image while retaining its security-scoped access.
    func open(url: URL)
    {
        let needsStop = url.startAccessingSecurityScopedResource()

        do
        {
            let loadedPhoto = try LoadedPhoto(url: url)
            releaseActiveSecurityScopedResource()
            activeSecurityScopedURL = url
            activeURLNeedsStop = needsStop
            photo = loadedPhoto
            resetPhotoProcessing()
            resetCrop()
            addRecentPhoto(url)
            message = "Loaded \(url.lastPathComponent) (\(loadedPhoto.cgImage.width) × \(loadedPhoto.cgImage.height) pixels)."
            showsError = false
        }
        catch
        {
            if needsStop
            {
                url.stopAccessingSecurityScopedResource()
            }
            report(error)
        }
    }

    /// Removes recent-file bookmarks and the older path-based history.
    func clearRecentPhotos()
    {
        recentPhotoURLs = []
        recentPhotoBookmarks = []
        UserDefaults.standard.removeObject(forKey: Self.recentPhotoBookmarksKey)
        UserDefaults.standard.removeObject(forKey: Self.legacyRecentPhotosKey)
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

    /// Applies a normalized drag offset and confines the selection to the photo.
    func moveCrop(normalizedTranslation: CGSize, from startRect: CGRect)
    {
        let moved = startRect.offsetBy(dx: normalizedTranslation.width, dy: normalizedTranslation.height)
        normalizedCrop = CropGeometry.clamp(moved, to: CGRect(x: 0, y: 0, width: 1, height: 1))
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

    /// Exports a new file beside the selected source and reports recoverable failures.
    func cropAndSave()
    {
        guard let photo
        else
        {
            return
        }
        do
        {
            let outputURL = try ImageExporter.export(
                photo: photo,
                sourceImage: processedImage ?? photo.cgImage,
                normalizedCrop: normalizedCrop,
                settings: settings,
                decoration: decoration,
                remoteFrameURL: cachedFrameURL
            )
            message = "Saved \(outputURL.lastPathComponent)"
            showsError = false
            NSWorkspace.shared.activateFileViewerSelecting([outputURL])
        }
        catch
        {
            report(error)
        }
    }

    /// Opens sheet options only when the preset defines physical print dimensions.
    func showPrintSheetPanel()
    {
        guard canCreatePrintSheet
        else
        {
            return
        }
        printSheetSettings.paperSize = settings.paperSize
        showsPrintSheetOptions = true
    }

    /// Exports physical sheet files and reveals only completed outputs in Finder.
    func createPrintSheet()
    {
        guard let photo
        else
        {
            return
        }
        do
        {
            let output = try ImageExporter.createPrintSheet(
                photo: photo,
                sourceImage: processedImage ?? photo.cgImage,
                normalizedCrop: normalizedCrop,
                settings: settings,
                decoration: decoration,
                remoteFrameURL: cachedFrameURL,
                sheetSettings: printSheetSettings
            )
            showPrintSheetOutput(output)
        }
        catch
        {
            report(error)
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
              FileManager.default.fileExists(atPath: sampleURL.path)
        else
        {
            return
        }

        open(url: sampleURL)
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

    /// Stores a bounded security-scoped bookmark list without copying photo bytes.
    private func addRecentPhoto(_ url: URL)
    {
        let standardizedURL = url.standardizedFileURL

        guard let bookmark = try? standardizedURL.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else
        {
            return
        }

        if let existingIndex = recentPhotoURLs.firstIndex(where: {
            $0.standardizedFileURL == standardizedURL
        })
        {
            recentPhotoURLs.remove(at: existingIndex)
            recentPhotoBookmarks.remove(at: existingIndex)
        }

        recentPhotoURLs.insert(standardizedURL, at: 0)
        recentPhotoBookmarks.insert(bookmark, at: 0)
        if recentPhotoURLs.count > Self.maximumRecentPhotos
        {
            recentPhotoURLs.removeLast(recentPhotoURLs.count - Self.maximumRecentPhotos)
            recentPhotoBookmarks.removeLast(recentPhotoBookmarks.count - Self.maximumRecentPhotos)
        }
        saveRecentPhotoBookmarks()
    }

    /// Resolves stored bookmarks and removes legacy plain-path history.
    private func restoreRecentPhotos()
    {
        let storedBookmarks = UserDefaults.standard.array(
            forKey: Self.recentPhotoBookmarksKey
        ) as? [Data] ?? []

        for bookmark in storedBookmarks.prefix(Self.maximumRecentPhotos)
        {
            restoreBookmark(bookmark)
        }

        saveRecentPhotoBookmarks()
        UserDefaults.standard.removeObject(forKey: Self.legacyRecentPhotosKey)
    }

    /// Persists only the bounded bookmark list in local user defaults.
    private func saveRecentPhotoBookmarks()
    {
        UserDefaults.standard.set(
            recentPhotoBookmarks,
            forKey: Self.recentPhotoBookmarksKey
        )
    }

    /// Balances the active file-access grant before opening another source.
    private func releaseActiveSecurityScopedResource()
    {
        if activeURLNeedsStop, let activeSecurityScopedURL
        {
            activeSecurityScopedURL.stopAccessingSecurityScopedResource()
        }
        activeSecurityScopedURL = nil
        activeURLNeedsStop = false
    }

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

    /// Announces saved outputs and selects the completed files in Finder.
    private func showPrintSheetOutput(_ output: PrintSheetOutput)
    {
        if output.jpegURL == nil
        {
            message = "Saved a \(output.copyCount)-copy PDF print sheet. The JPEG exceeded the safe raster limit."
        }
        else
        {
            message = "Saved a \(output.copyCount)-copy print sheet as JPEG and PDF."
        }
        showsError = false
        let outputURLs = [output.jpegURL, output.pdfURL].compactMap
        {
            $0
        }
        NSWorkspace.shared.activateFileViewerSelecting(outputURLs)
    }

    /// Resolves one security-scoped bookmark and refreshes its stored representation when stale.
    private func restoreBookmark(_ bookmark: Data)
    {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else
        {
            return
        }

        recentPhotoURLs.append(url)
        if isStale,
           let refreshedBookmark = try? url.bookmarkData(
               options: .withSecurityScope,
               includingResourceValuesForKeys: nil,
               relativeTo: nil
           )
        {
            recentPhotoBookmarks.append(refreshedBookmark)
        }
        else
        {
            recentPhotoBookmarks.append(bookmark)
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
}
