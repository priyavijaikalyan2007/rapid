// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f5be557d-3153-494f-8f51-ec11462d4028
// Created: 2026
// COMPONENT: ContentView
// PURPOSE: Composes the native ContentView user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> ContentView -> local result.

import AppKit
import SwiftUI
import UniformTypeIdentifiers

#if DEBUG
private var appStoreScreenshotBackgroundWindow: NSWindow?
#endif

/// Composes the native ContentView user interface.
struct ContentView: View
{
    /// Open window used by ContentView.
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var document: PhotoDocument
    @EnvironmentObject private var resourceLibrary: ResourceLibrary
    @State private var isDropTargeted = false
    @State private var showsScreenshotResources = false
    @State private var sidebarMode = SidebarMode.decorate

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        editorNavigation
            .toolbar
            {
                editorToolbar
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
            .sheet(isPresented: $document.showsPrintSheetOptions)
            {
                printSheetOptions
            }
            .sheet(isPresented: $showsScreenshotResources)
            {
                ResourceLibraryView()
                    .environmentObject(resourceLibrary)
            }
    }

    /// Settings panel used by ContentView.
    private var settingsPanel: some View
    {
        Form
        {
            photoSection

            if document.settings.isPrintPreset
            {
                paperSection
            }

            outputSection

            Spacer()

            Text(document.message)
                .font(.caption)
                .foregroundStyle(document.showsError ? .red : .secondary)
                .textSelection(.enabled)
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }

    /// Canvas used by ContentView.
    @ViewBuilder
    private var canvas: some View
    {
        if let photo = document.photo,
           let displayImage = document.displayImage
        {
            CropCanvas(
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
            .padding(20)
            .background(Color(nsColor: .underPageBackgroundColor))
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted, perform: handleDrop)
        }
        else
        {
            emptyPhotoView
                .dropDestination(for: URL.self)
                { urls, _ in
                    guard let url = urls.first
                    else
                    {
                        return false
                    }
                    document.open(url: url)
                    return true
                }
        }
    }

    /// Remote frame image used by ContentView.
    private var remoteFrameImage: Image?
    {
        guard let id = document.decoration.remoteFrameID,
              let url = resourceLibrary.cachedFileURL(for: id),
              let image = NSImage(contentsOf: url)
        else
        {
            return nil
        }
        return Image(nsImage: image)
    }

    /// Supports background removal used by ContentView.
    private var supportsBackgroundRemoval: Bool
    {
        let category = document.settings.preset.category
        return category == .passport || category == .instagram
    }

    /// Accepts the first dropped file URL and opens it on the main actor.
    private func handleDrop(providers: [NSItemProvider]) -> Bool
    {
        guard let provider = providers.first
        else
        {
            return false
        }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil)
        { item, _ in
            let url: URL?
            if let data = item as? Data
            {
                url = URL(dataRepresentation: data, relativeTo: nil)
            }
            else
            {
                url = item as? URL
            }
            if let url
            {
                Task
                { @MainActor in
                    document.open(url: url)
                }
            }
        }
        return true
    }

    /// Routes debug capture scenarios through the normal application screens.
    private func prepareAppStoreScreenshot()
    {
        #if DEBUG
        configureAppStoreScreenshotWindow()
        switch AppStoreScreenshotScenario.current
        {
        case .printSheet, .trueSize:
            document.showPrintSheetPanel()
        case .resources:
            showsScreenshotResources = true
        case .preview:
            playAppStorePreview()
        default:
            break
        }
        #endif
    }

    #if DEBUG
    /// Sizes the debug capture window without changing normal window behavior.
    private func configureAppStoreScreenshotWindow()
    {
        guard let scenario = AppStoreScreenshotScenario.current
        else
        {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
        {
            guard let window = NSApp.windows.first(where: \.isVisible),
                  let screen = window.screen ?? NSScreen.main
            else
            {
                return
            }
            let height: CGFloat = scenario == .preview ? 720 : 800
            let frame = CGRect(
                x: screen.visibleFrame.minX + 100,
                y: screen.visibleFrame.maxY - height - 80,
                width: 1280,
                height: height
            )
            Self.showScreenshotBackground(screenFrame: screen.frame)
            window.setFrame(frame, display: true)
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

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
            document.showPrintSheetPanel()
        }
    }

    /// Covers unrelated desktop content during an explicitly requested debug media capture.
    private static func showScreenshotBackground(screenFrame: CGRect)
    {
        let backgroundWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        backgroundWindow.backgroundColor = .windowBackgroundColor
        backgroundWindow.ignoresMouseEvents = true
        backgroundWindow.orderFront(nil)
        appStoreScreenshotBackgroundWindow = backgroundWindow
    }
    #endif

    /// Builds the preset picker using the same local state.
    @ViewBuilder
    private var presetPicker: some View
    {
        Picker("Crop size", selection: $document.settings.preset)
        {
            ForEach(PresetCategory.allCases)
            { category in
                Section(category.rawValue)
                {
                    ForEach(CropPreset.allCases.filter
                    {
                        $0.category == category
                    })
                    { preset in
                        Text(preset.title).tag(preset)
                    }
                }
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

    /// Builds the photo section using the same local state.
    @ViewBuilder
    private var photoSection: some View
    {
        Section("Photo")
        {
            presetPicker

            if document.settings.preset.supportsOrientation
            {
                orientationPicker
                    .pickerStyle(.segmented)
            }
        }
    }

    /// Builds the paper section using the same local state.
    @ViewBuilder
    private var paperSection: some View
    {
        Section("Paper")
        {
            Picker("Paper size", selection: $document.settings.paperSize)
            {
                ForEach(PaperSize.allCases)
                { size in
                    Text(size.rawValue).tag(size)
                }
            }

            Toggle("Add 0.25-inch white margin", isOn: $document.settings.includesMargin)

            if !document.settings.fitsPaper
            {
                Label("The print size exceeds this paper size.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    /// Builds the passport information using the same local state.
    @ViewBuilder
    private var passportInformation: some View
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
                    """
                    This preset is for digital submission. Select a Passport Print preset to create a \
                    print sheet.
                    """
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    /// Builds the output section using the same local state.
    @ViewBuilder
    private var outputSection: some View
    {
        Section("Output")
        {
            Text("Drag inside the rectangle to move it. Drag a corner handle to resize it.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("The app saves a new file beside the original. It never changes the original file.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if document.settings.isPrintPreset && document.settings.includesMargin
            {
                Text("The white margin stays inside the selected print size.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            passportInformation
        }
    }

    /// Builds the editor sidebar using the same local state.
    @ViewBuilder
    private var editorSidebar: some View
    {
        VStack(spacing: 0)
        {
            Picker("Editor", selection: $sidebarMode)
            {
                ForEach(SidebarMode.allCases)
                { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            switch sidebarMode
            {
            case .decorate:
                DecorationEditorView(settings: $document.decoration, showsDoneButton: false)
                    .environmentObject(resourceLibrary)
            case .adjust:
                PhotoAdjustmentEditor(
                    settings: $document.adjustments,
                    allowsBackgroundRemoval: supportsBackgroundRemoval,
                    isPassportPhoto: document.settings.isPassportPreset,
                    isProcessing: document.isProcessingPhoto
                )
            }
        }
    }

    /// Builds the open photo button using the same local state.
    @ViewBuilder
    private var openPhotoButton: some View
    {
        Button
        {
            document.showOpenPanel()
        } label: {
            Label("Open Photo", systemImage: "photo.badge.plus")
        }
    }

    /// Builds the center crop button using the same local state.
    @ViewBuilder
    private var centerCropButton: some View
    {
        Button
        {
            document.resetCrop()
        } label: {
            Label("Center Crop", systemImage: "scope")
        }
    }

    /// Builds the save crop button using the same local state.
    @ViewBuilder
    private var saveCropButton: some View
    {
        Button
        {
            document.cropAndSave()
        } label: {
            Label("Crop and Save", systemImage: "crop")
        }
    }

    /// Builds the print sheet button using the same local state.
    @ViewBuilder
    private var printSheetButton: some View
    {
        Button
        {
            document.showPrintSheetPanel()
        } label: {
            Label("Create Print Sheet", systemImage: "square.grid.2x2")
        }
    }

    /// Builds the help button using the same local state.
    @ViewBuilder
    private var helpButton: some View
    {
        Button
        {
            openWindow(id: "cropprint-help")
        } label: {
            Label("CropPrint Help", systemImage: "questionmark.circle")
        }
    }

    /// Builds the editor toolbar using the same local state.
    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent
    {
        ToolbarItemGroup
        {
            openPhotoButton
                .help("Open a photo from disk.")

            centerCropButton
                .disabled(document.photo == nil)
                .help("Center the crop rectangle at its largest size.")

            saveCropButton
                .disabled(!document.canExport)
                .help("Crop the selected area and save a new image beside the original.")

            printSheetButton
                .disabled(!document.canCreatePrintSheet)
                .help("Tile the crop at an exact physical size on printable paper.")

            helpButton
                .help("Open instructions for CropPrint.")
        }
    }

    /// Builds the editor navigation using the same local state.
    @ViewBuilder
    private var editorNavigation: some View
    {
        NavigationSplitView
        {
            settingsPanel
                .navigationSplitViewColumnWidth(min: 245, ideal: 270, max: 320)
        } content: {
            canvas
                .navigationSplitViewColumnWidth(min: 520, ideal: 700)
        } detail: {
            editorSidebar
                .navigationSplitViewColumnWidth(min: 300, ideal: 340, max: 400)
        }
    }

    /// Builds the print sheet options using the same local state.
    @ViewBuilder
    private var printSheetOptions: some View
    {
        if document.settings.preset.physicalInches != nil
        {
            let orientedSize = document.settings.preset.dimensions(
                for: document.settings.orientation
            )
            PrintSheetOptionsView(
                settings: $document.printSheetSettings,
                photoSizeInches: orientedSize,
                previewImage: document.croppedPreviewImage,
                onCreate: document.createPrintSheet
            )
        }
    }

    /// Builds the empty photo view using the same local state.
    @ViewBuilder
    private var emptyPhotoView: some View
    {
        ContentUnavailableView
        {
            Label("No Photo", systemImage: "photo")
        }
        description: {
            Text("Open a photo or drag one into this window.")
        } actions: {
            Button("Open Photo…")
            {
                document.showOpenPanel()
            }
            .keyboardShortcut(.defaultAction)
        }
    }
}
