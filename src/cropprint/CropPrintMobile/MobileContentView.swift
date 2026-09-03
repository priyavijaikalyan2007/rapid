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

                        Button("Attributions", systemImage: "doc.text") {
                            informationPage = .attributions
                        }

                        Button("CropPrint Help", systemImage: "questionmark.circle") {
                            informationPage = .help
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
                document.resetCrop()
            }
            .onChange(of: document.settings.orientation) { _, _ in document.resetCrop() }
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
                }
            }
            .sheet(isPresented: $showsPrintSheetOptions) {
                if document.settings.preset.physicalInches != nil {
                    PrintSheetOptionsView(
                        settings: $document.printSheetSettings,
                        photoSizeInches: document.settings.preset.dimensions(
                            for: document.settings.orientation
                        ),
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
        if let photo = document.photo {
            MobileCropCanvas(
                photo: photo,
                normalizedCrop: $document.normalizedCrop,
                aspectRatio: document.settings.aspectRatio,
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
            Picker("Crop size", selection: $document.settings.preset) {
                ForEach(PresetCategory.allCases) { category in
                    Section(category.rawValue) {
                        ForEach(CropPreset.allCases.filter { $0.category == category }) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
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
                Text("This preset sets only the outer dimensions. Check head size, background, and current government rules before submission.")
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
}

private enum InformationPage: String, Identifiable {
    case about
    case attributions
    case resources
    case help
    case decorate

    var id: String { rawValue }
}
