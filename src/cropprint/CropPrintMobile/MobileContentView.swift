// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 2656d59f-1a22-4129-9d69-62d61bbd651d
// Created: 2026
// COMPONENT: MobileContentView
// PURPOSE: Composes the native MobileContentView user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> MobileContentView -> local result.

import PhotosUI
import SwiftUI

/// Composes the native MobileContentView user interface.
struct MobileContentView: View
{
    /// Resource library used by MobileContentView.
    @EnvironmentObject private var resourceLibrary: ResourceLibrary
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var document = MobilePhotoDocument()
    @State private var selectedItem: PhotosPickerItem?
    @State private var informationPage: InformationPage?
    @State private var showsPrintSheetOptions = false

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        editorNavigation
    }

    /// Compact layout used by MobileContentView.
    private var compactLayout: some View
    {
        VStack(spacing: 12)
        {
            photoCanvas
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            controls
            actions
        }
        .padding(.vertical)
    }

    /// Regular layout used by MobileContentView.
    private var regularLayout: some View
    {
        HStack(spacing: 0)
        {
            photoCanvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

            Divider()

            ScrollView
            {
                VStack(spacing: 16)
                {
                    controls
                    actions
                }
                .padding(.vertical)
            }
            .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
        }
    }

    /// Photo canvas used by MobileContentView.
    @ViewBuilder
    private var photoCanvas: some View
    {
        if let photo = document.photo,
           let displayImage = document.displayImage
        {
            MobileCropCanvas(
                photo: photo,
                displayImage: displayImage,
                normalizedCrop: $document.normalizedCrop,
                aspectRatio: document.settings.aspectRatio,
                passportGuide: document.settings.isPassportPreset
                    && document.settings.showsPassportGuide
                    ? document.settings.preset.passportGuide
                    : nil,
                decoration: $document.decoration,
                remoteFrame: remoteFrameImage
            )
        }
        else
        {
            ContentUnavailableView(
                "No Photo",
                systemImage: "photo",
                description: Text("Choose a photo from your library.")
            )
        }
    }

    /// Actions used by MobileContentView.
    private var actions: some View
    {
        VStack(spacing: 12)
        {
            saveButton
                .buttonStyle(.borderedProminent)
                .disabled(!document.canSave)

            printSheetButton
                .buttonStyle(.bordered)
                .disabled(!document.canCreatePrintSheet)

            Text(document.message)
                .font(.caption)
                .foregroundStyle(document.showsError ? .red : .secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }

    /// Remote frame image used by MobileContentView.
    private var remoteFrameImage: Image?
    {
        guard let id = document.decoration.remoteFrameID,
              let url = resourceLibrary.cachedFileURL(for: id),
              let image = UIImage(contentsOfFile: url.path)
        else
        {
            return nil
        }
        return Image(uiImage: image)
    }

    /// Controls used by MobileContentView.
    private var controls: some View
    {
        VStack(spacing: 10)
        {
            categoryPicker
                .pickerStyle(.menu)

            presetPicker
                .pickerStyle(.menu)

            if document.settings.preset.supportsOrientation
            {
                orientationPicker
                    .pickerStyle(.segmented)
            }

            printControls

            passportControls
        }
        .padding(.horizontal)
    }

    /// Preset category used by MobileContentView.
    private var presetCategory: Binding<PresetCategory>
    {
        Binding(
            get: {
                document.settings.preset.category
            },
            set: { category in
                guard let firstPreset = category.presets.first
                else
                {
                    return
                }
                document.settings.preset = firstPreset
            }
        )
    }

    /// Supports background removal used by MobileContentView.
    private var supportsBackgroundRemoval: Bool
    {
        let category = document.settings.preset.category
        return category == .passport || category == .instagram
    }

    /// Routes debug capture scenarios through the normal application screens.
    private func prepareAppStoreScreenshot()
    {
        #if DEBUG
        switch AppStoreScreenshotScenario.current
        {
        case .decorate:
            informationPage = .decorate
        case .resources:
            informationPage = .resources
        case .printSheet, .trueSize:
            showsPrintSheetOptions = true
        case .preview:
            playAppStorePreview()
        default:
            break
        }
        #endif
    }

    #if DEBUG
    /// Runs the fixed debug demonstration without saving the source photo.
    private func playAppStorePreview()
    {
        Task
        { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            document.decoration.text = "Make it yours"
            document.decoration.textStyle = .shadow
            document.decoration.frameStyle = .double
            document.decoration.frameColor = .gold

            try? await Task.sleep(nanoseconds: 4_000_000_000)
            document.settings.preset = .passportUS
            document.settings.paperSize = .fiveBySeven
            document.resetCrop()

            try? await Task.sleep(nanoseconds: 4_000_000_000)
            showsPrintSheetOptions = true
        }
    }
    #endif

    /// Builds the category picker using the same local state.
    @ViewBuilder
    private var categoryPicker: some View
    {
        Picker("Category", selection: presetCategory)
        {
            ForEach(PresetCategory.allCases)
            { category in
                Text(category.rawValue).tag(category)
            }
        }
    }

    /// Builds the preset picker using the same local state.
    @ViewBuilder
    private var presetPicker: some View
    {
        Picker("Crop size", selection: $document.settings.preset)
        {
            ForEach(document.settings.preset.category.presets)
            { preset in
                Text(preset.title).tag(preset)
            }
        }
    }

    /// Builds the orientation picker using the same local state.
    @ViewBuilder
    private var orientationPicker: some View
    {
        Picker("Orientation", selection: $document.settings.orientation)
        {
            ForEach(PrintOrientation.allCases)
            { orientation in
                Text(orientation.title).tag(orientation)
            }
        }
    }

    /// Builds the paper picker using the same local state.
    @ViewBuilder
    private var paperPicker: some View
    {
        Picker("Paper", selection: $document.settings.paperSize)
        {
            ForEach(PaperSize.allCases)
            { paper in
                Text(paper.rawValue).tag(paper)
            }
        }
    }

    /// Builds the print controls using the same local state.
    @ViewBuilder
    private var printControls: some View
    {
        if document.settings.isPrintPreset
        {
            paperPicker
                .pickerStyle(.menu)

            Toggle("Add 0.25-inch white margin", isOn: $document.settings.includesMargin)

            if !document.settings.fitsPaper
            {
                Label("The print size exceeds this paper size.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    /// Builds the passport controls using the same local state.
    @ViewBuilder
    private var passportControls: some View
    {
        if document.settings.isPassportPreset
        {
            Toggle("Show passport head guide", isOn: $document.settings.showsPassportGuide)

            if let guide = document.settings.preset.passportGuide
            {
                Text(guide.measurement)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("Open current rules from \(guide.sourceName)", destination: guide.sourceURL)
                    .font(.caption)
            }

            Text("The guide is a visual aid. Check the current government rules before submission.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if document.settings.preset.physicalInches == nil
            {
                Text(
                    "This preset is for digital submission. Select a Passport Print preset to create a print sheet."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    /// Builds the save button using the same local state.
    @ViewBuilder
    private var saveButton: some View
    {
        Button
        {
            document.saveToPhotos()
        } label: {
            Label("Crop and Save to Photos", systemImage: "crop")
                .frame(maxWidth: .infinity)
        }
    }

    /// Builds the print sheet button using the same local state.
    @ViewBuilder
    private var printSheetButton: some View
    {
        Button
        {
            document.printSheetSettings.paperSize = document.settings.paperSize
            showsPrintSheetOptions = true
        } label: {
            Label("Create Print Sheet", systemImage: "square.grid.2x2")
                .frame(maxWidth: .infinity)
        }
    }

    /// Builds the editor menu using the same local state.
    @ViewBuilder
    private var editorMenu: some View
    {
        Menu
        {
            Button("Center Crop", systemImage: "scope")
            {
                document.resetCrop()
            }
            .disabled(document.photo == nil)

            Divider()

            Button("Remote Resources", systemImage: "square.and.arrow.down")
            {
                informationPage = .resources
            }

            Button("Decorate", systemImage: "textformat")
            {
                informationPage = .decorate
            }
            .disabled(document.photo == nil)

            Button("Adjust Photo", systemImage: "slider.horizontal.3")
            {
                informationPage = .adjust
            }
            .disabled(document.photo == nil)

            attributionsButton

            helpButton

            Link(
                destination: URL(string: "https://github.com/priyavijaikalyan2007/rapid/issues/new/choose")!
            )
            {
                Label("Report an Issue", systemImage: "exclamationmark.bubble")
            }

            aboutButton
        } label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }

    /// Builds the menu toolbar using the same local state.
    @ToolbarContentBuilder
    private var menuToolbar: some ToolbarContent
    {
        ToolbarItem(placement: .topBarLeading)
        {
            editorMenu
        }
    }

    /// Builds the photo toolbar using the same local state.
    @ToolbarContentBuilder
    private var photoToolbar: some ToolbarContent
    {
        ToolbarItem(placement: .topBarTrailing)
        {
            PhotosPicker(selection: $selectedItem, matching: .images)
            {
                Label("Choose Photo", systemImage: "photo.badge.plus")
            }
        }
    }

    /// Builds the editor navigation using the same local state.
    @ViewBuilder
    private var editorNavigation: some View
    {
        NavigationStack
        {
            Group
            {
                if horizontalSizeClass == .regular
                {
                    regularLayout
                }
                else
                {
                    compactLayout
                }
            }
            .navigationTitle("CropPrint")
            .toolbar
            {
                menuToolbar

                photoToolbar
            }
            .task(id: selectedItem)
            {
                await importSelectedPhoto()
            }
            .onChange(of: document.settings.preset)
            { _, preset in
                if preset.category == .monitor
                {
                    document.settings.orientation = .landscape
                }
                if preset.category != .passport && preset.category != .instagram
                {
                    document.adjustments.background = .original
                }
                document.resetCrop()
            }
            .onChange(of: document.settings.orientation)
            { _, _ in
                document.resetCrop()
            }
            .onChange(of: document.adjustments)
            { _, _ in
                document.updatePhotoProcessing()
            }
            .onAppear(perform: prepareAppStoreScreenshot)
            .sheet(item: $informationPage)
            { page in
                informationView(page: page)
            }
            .sheet(isPresented: $showsPrintSheetOptions)
            {
                printSheetOptions
            }
        }
    }

    /// Builds the information view using the same local state.
    @ViewBuilder
    private func informationView(page: InformationPage) -> some View
    {
        switch page
        {
        case .about:
            AboutCropPrintView()
        case .attributions:
            AttributionsView()
                .environmentObject(resourceLibrary)
        case .resources:
            ResourceLibraryView()
                .environmentObject(resourceLibrary)
        case .help:
            CropPrintHelpView()
        case .decorate:
            DecorationEditorView(settings: $document.decoration)
                .environmentObject(resourceLibrary)
                .presentationDetents([.height(330), .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(330)))
        case .adjust:
            adjustmentNavigation
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
    }

    /// Builds the adjustment navigation using the same local state.
    @ViewBuilder
    private var adjustmentNavigation: some View
    {
        NavigationStack
        {
            PhotoAdjustmentEditor(
                settings: $document.adjustments,
                allowsBackgroundRemoval: supportsBackgroundRemoval,
                isPassportPhoto: document.settings.isPassportPreset,
                isProcessing: document.isProcessingPhoto,
                showsDoneButton: true
            )
        }
    }

    /// Builds the print sheet options using the same local state.
    @ViewBuilder
    private var printSheetOptions: some View
    {
        if document.settings.preset.physicalInches != nil
        {
            PrintSheetOptionsView(
                settings: $document.printSheetSettings,
                photoSizeInches: document.settings.preset.dimensions(
                    for: document.settings.orientation
                ),
                previewImage: document.croppedPreviewImage,
                onCreate: document.createPrintSheetInPhotos
            )
        }
    }

    /// Builds the attributions button using the same local state.
    @ViewBuilder
    private var attributionsButton: some View
    {
        Button("Attributions", systemImage: "doc.text")
        {
            informationPage = .attributions
        }
    }

    /// Builds the help button using the same local state.
    @ViewBuilder
    private var helpButton: some View
    {
        Button("CropPrint Help", systemImage: "questionmark.circle")
        {
            informationPage = .help
        }
    }

    /// Builds the about button using the same local state.
    @ViewBuilder
    private var aboutButton: some View
    {
        Button("About CropPrint", systemImage: "info.circle")
        {
            informationPage = .about
        }
    }

    /// Cancels stale picker requests and publishes only a bounded, current file transfer.
    @MainActor
    private func importSelectedPhoto() async
    {
        guard let item = selectedItem
        else
        {
            return
        }
        do
        {
            guard let imported = try await item.loadTransferable(type: ImportedPhoto.self)
            else
            {
                throw MobilePhotoError.unreadableImage
            }
            try Task.checkCancellation()
            document.load(data: imported.data)
        }
        catch is CancellationError
        {
            return
        }
        catch
        {
            guard !Task.isCancelled
            else
            {
                return
            }
            document.reportImportFailure(error)
        }
    }
}
