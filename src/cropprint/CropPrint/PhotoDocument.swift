import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class PhotoDocument: ObservableObject {
    private static let legacyRecentPhotosKey = "recentPhotoPaths"
    private static let recentPhotoBookmarksKey = "recentPhotoBookmarks"
    private static let maximumRecentPhotos = 10

    private var recentPhotoBookmarks: [Data] = []
    private var activeSecurityScopedURL: URL?
    private var activeURLNeedsStop = false
    private var personMask: CGImage?
    private var processingTask: Task<Void, Never>?

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

    init() {
        restoreRecentPhotos()
#if DEBUG
        loadAppStoreScreenshotSampleIfNeeded()
#endif
    }

    var canExport: Bool {
        photo != nil && normalizedCrop.width > 0 && normalizedCrop.height > 0
            && !isProcessingPhoto
    }

    var canCreatePrintSheet: Bool {
        canExport && settings.preset.physicalInches != nil
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

    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.title = "Open Photo"
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        open(url: url)
    }

    func open(url: URL) {
        let needsStop = url.startAccessingSecurityScopedResource()

        do {
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
        } catch {
            if needsStop {
                url.stopAccessingSecurityScopedResource()
            }
            report(error)
        }
    }

    func clearRecentPhotos() {
        recentPhotoURLs = []
        recentPhotoBookmarks = []
        UserDefaults.standard.removeObject(forKey: Self.recentPhotoBookmarksKey)
        UserDefaults.standard.removeObject(forKey: Self.legacyRecentPhotosKey)
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

    func moveCrop(normalizedTranslation: CGSize, from startRect: CGRect) {
        let moved = startRect.offsetBy(dx: normalizedTranslation.width, dy: normalizedTranslation.height)
        normalizedCrop = CropGeometry.clamp(moved, to: CGRect(x: 0, y: 0, width: 1, height: 1))
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

    func cropAndSave() {
        guard let photo else { return }
        do {
            let outputURL = try ImageExporter.export(
                photo: photo,
                sourceImage: processedImage ?? photo.cgImage,
                normalizedCrop: normalizedCrop,
                settings: settings,
                decoration: decoration,
                remoteFrameURL: decoration.remoteFrameID.flatMap {
                    ResourceLibrary.shared.cachedFileURL(for: $0)
                }
            )
            message = "Saved \(outputURL.lastPathComponent)"
            showsError = false
            NSWorkspace.shared.activateFileViewerSelecting([outputURL])
        } catch {
            report(error)
        }
    }

    func showPrintSheetPanel() {
        guard canCreatePrintSheet else { return }
        printSheetSettings.paperSize = settings.paperSize
        showsPrintSheetOptions = true
    }

    func createPrintSheet() {
        guard let photo else { return }
        do {
            let output = try ImageExporter.createPrintSheet(
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
            if output.jpegURL == nil {
                message = "Saved a \(output.copyCount)-copy PDF print sheet. The JPEG exceeded the safe raster limit."
            } else {
                message = "Saved a \(output.copyCount)-copy print sheet as JPEG and PDF."
            }
            showsError = false
            let outputURLs = [output.jpegURL, output.pdfURL].compactMap { $0 }
            NSWorkspace.shared.activateFileViewerSelecting(outputURLs)
        } catch {
            report(error)
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
              FileManager.default.fileExists(atPath: sampleURL.path) else {
            return
        }

        open(url: sampleURL)
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


    private func addRecentPhoto(_ url: URL) {
        let standardizedURL = url.standardizedFileURL

        guard let bookmark = try? standardizedURL.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else {
            return
        }

        if let existingIndex = recentPhotoURLs.firstIndex(where: {
            $0.standardizedFileURL == standardizedURL
        }) {
            recentPhotoURLs.remove(at: existingIndex)
            recentPhotoBookmarks.remove(at: existingIndex)
        }

        recentPhotoURLs.insert(standardizedURL, at: 0)
        recentPhotoBookmarks.insert(bookmark, at: 0)
        if recentPhotoURLs.count > Self.maximumRecentPhotos {
            recentPhotoURLs.removeLast(recentPhotoURLs.count - Self.maximumRecentPhotos)
            recentPhotoBookmarks.removeLast(recentPhotoBookmarks.count - Self.maximumRecentPhotos)
        }
        saveRecentPhotoBookmarks()
    }

    private func restoreRecentPhotos() {
        let storedBookmarks = UserDefaults.standard.array(
            forKey: Self.recentPhotoBookmarksKey
        ) as? [Data] ?? []

        for bookmark in storedBookmarks.prefix(Self.maximumRecentPhotos) {
            var isStale = false
            guard let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: [.withSecurityScope, .withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) else {
                continue
            }

            recentPhotoURLs.append(url)
            if isStale,
               let refreshedBookmark = try? url.bookmarkData(
                   options: .withSecurityScope,
                   includingResourceValuesForKeys: nil,
                   relativeTo: nil
               ) {
                recentPhotoBookmarks.append(refreshedBookmark)
            } else {
                recentPhotoBookmarks.append(bookmark)
            }
        }

        saveRecentPhotoBookmarks()
        UserDefaults.standard.removeObject(forKey: Self.legacyRecentPhotosKey)
    }

    private func saveRecentPhotoBookmarks() {
        UserDefaults.standard.set(
            recentPhotoBookmarks,
            forKey: Self.recentPhotoBookmarksKey
        )
    }

    private func releaseActiveSecurityScopedResource() {
        if activeURLNeedsStop, let activeSecurityScopedURL {
            activeSecurityScopedURL.stopAccessingSecurityScopedResource()
        }
        activeSecurityScopedURL = nil
        activeURLNeedsStop = false
    }
}
