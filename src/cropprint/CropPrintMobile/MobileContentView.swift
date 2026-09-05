import PhotosUI
import SwiftUI

struct MobileContentView: View {
    @EnvironmentObject private var resourceLibrary: ResourceLibrary
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var document = MobilePhotoDocument()
    @State private var selectedItem: PhotosPickerItem?
    @State private var informationPage: InformationPage?
    @State private var showsPrintSheetOptions = false

    var body: some View {
        NavigationStack {
            Group {
                if horizontalSizeClass == .regular {
                    regularLayout
                } else {
                    compactLayout
                }
            }
            .navigationTitle("CropPrint")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Center Crop", systemImage: "scope") {
                            document.resetCrop()
                        }
                        .disabled(document.photo == nil)

                        Divider()

                        Button("Remote Resources", systemImage: "square.and.arrow.down") {
                            informationPage = .resources
                        }

                        Button("Decorate", systemImage: "textformat") {
                            informationPage = .decorate
                        }
                        .disabled(document.photo == nil)

                        Button("Adjust Photo", systemImage: "slider.horizontal.3") {
                            informationPage = .adjust
                        }
                        .disabled(document.photo == nil)

                        Button("Attributions", systemImage: "doc.text") {
                            informationPage = .attributions
                        }

                        Button("CropPrint Help", systemImage: "questionmark.circle") {
                            informationPage = .help
                        }

                        Link(destination: URL(string: "https://github.com/priyavijaikalyan2007/rapid/issues/new/choose")!) {
                            Label("Report an Issue", systemImage: "exclamationmark.bubble")
                        }

                        Button("About CropPrint", systemImage: "info.circle") {
                            informationPage = .about
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Choose Photo", systemImage: "photo.badge.plus")
                    }
                }
            }
            .onChange(of: selectedItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        document.load(data: data)
                    }
                }
            }
            .onChange(of: document.settings.preset) { _, preset in
                if preset.category == .monitor {
                    document.settings.orientation = .landscape
                }
                if preset.category != .passport && preset.category != .instagram {
                    document.adjustments.background = .original
                }
                document.resetCrop()
            }
            .onChange(of: document.settings.orientation) { _, _ in document.resetCrop() }
            .onChange(of: document.adjustments) { _, _ in document.updatePhotoProcessing() }
            .onAppear(perform: prepareAppStoreScreenshot)
            .sheet(item: $informationPage) { page in
                switch page {
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
                    NavigationStack {
                        PhotoAdjustmentEditor(
                            settings: $document.adjustments,
                            allowsBackgroundRemoval: supportsBackgroundRemoval,
                            isPassportPhoto: document.settings.isPassportPreset,
                            isProcessing: document.isProcessingPhoto,
                            showsDoneButton: true
                        )
                    }
                    .presentationDetents([.medium, .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                }
            }
            .sheet(isPresented: $showsPrintSheetOptions) {
                if document.settings.preset.physicalInches != nil {
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
        }
    }

    private var compactLayout: some View {
        VStack(spacing: 12) {
            photoCanvas
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            controls
            actions
        }
        .padding(.vertical)
    }

    private var regularLayout: some View {
        HStack(spacing: 0) {
            photoCanvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    controls
                    actions
                }
                .padding(.vertical)
            }
            .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
        }
    }

    @ViewBuilder
    private var photoCanvas: some View {
        if let photo = document.photo,
           let displayImage = document.displayImage {
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
        } else {
            ContentUnavailableView(
                "No Photo",
                systemImage: "photo",
                description: Text("Choose a photo from your library.")
            )
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                document.saveToPhotos()
            } label: {
                Label("Crop and Save to Photos", systemImage: "crop")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!document.canSave)

            Button {
                document.printSheetSettings.paperSize = document.settings.paperSize
                showsPrintSheetOptions = true
            } label: {
                Label("Create Print Sheet", systemImage: "square.grid.2x2")
                    .frame(maxWidth: .infinity)
            }
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

    private var remoteFrameImage: Image? {
        guard let id = document.decoration.remoteFrameID,
              let url = resourceLibrary.cachedFileURL(for: id),
              let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return Image(uiImage: image)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Picker("Category", selection: presetCategory) {
                ForEach(PresetCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.menu)

            Picker("Crop size", selection: $document.settings.preset) {
                ForEach(document.settings.preset.category.presets) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.menu)

            if document.settings.preset.supportsOrientation {
                Picker("Orientation", selection: $document.settings.orientation) {
                    ForEach(PrintOrientation.allCases) { orientation in
                        Text(orientation.title).tag(orientation)
                    }
                }
                .pickerStyle(.segmented)
            }

            if document.settings.isPrintPreset {
                Picker("Paper", selection: $document.settings.paperSize) {
                    ForEach(PaperSize.allCases) { paper in
                        Text(paper.rawValue).tag(paper)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Add 0.25-inch white margin", isOn: $document.settings.includesMargin)

                if !document.settings.fitsPaper {
                    Label("The print size exceeds this paper size.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            if document.settings.isPassportPreset {
                Toggle("Show passport head guide", isOn: $document.settings.showsPassportGuide)

                if let guide = document.settings.preset.passportGuide {
                    Text(guide.measurement)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link("Open current rules from \(guide.sourceName)", destination: guide.sourceURL)
                        .font(.caption)
                }

                Text("The guide is a visual aid. Check the current government rules before submission.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if document.settings.preset.physicalInches == nil {
                    Text("This preset is for digital submission. Select a Passport Print preset to create a print sheet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    private var presetCategory: Binding<PresetCategory> {
        Binding(
            get: { document.settings.preset.category },
            set: { category in
                guard let firstPreset = category.presets.first else { return }
                document.settings.preset = firstPreset
            }
        )
    }

    private var supportsBackgroundRemoval: Bool {
        let category = document.settings.preset.category
        return category == .passport || category == .instagram
    }

    private func prepareAppStoreScreenshot() {
#if DEBUG
        switch AppStoreScreenshotScenario.current {
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
    private func playAppStorePreview() {
        Task { @MainActor in
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
}

private enum InformationPage: String, Identifiable {
    case about
    case attributions
    case resources
    case help
    case decorate
    case adjust

    var id: String { rawValue }
}
