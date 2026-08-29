import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var document: PhotoDocument
    @EnvironmentObject private var resourceLibrary: ResourceLibrary
    @State private var isDropTargeted = false

    var body: some View {
        NavigationSplitView {
            settingsPanel
                .navigationSplitViewColumnWidth(min: 245, ideal: 270, max: 320)
        } content: {
            canvas
                .navigationSplitViewColumnWidth(min: 520, ideal: 700)
        } detail: {
            DecorationEditorView(settings: $document.decoration, showsDoneButton: false)
                .environmentObject(resourceLibrary)
                .navigationSplitViewColumnWidth(min: 285, ideal: 320, max: 380)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    document.showOpenPanel()
                } label: {
                    Label("Open Photo", systemImage: "photo.badge.plus")
                }
                .help("Open a photo from disk.")

                Button {
                    document.resetCrop()
                } label: {
                    Label("Center Crop", systemImage: "scope")
                }
                .disabled(document.photo == nil)
                .help("Center the crop rectangle at its largest size.")

                Button {
                    document.cropAndSave()
                } label: {
                    Label("Crop and Save", systemImage: "crop")
                }
                .disabled(!document.canExport)
                .help("Crop the selected area and save a new image beside the original.")

                Button {
                    document.showPrintSheetPanel()
                } label: {
                    Label("Create Print Sheet", systemImage: "square.grid.2x2")
                }
                .disabled(!document.canCreatePrintSheet)
                .help("Tile the crop at an exact physical size on printable paper.")

                Button {
                    openWindow(id: "cropprint-help")
                } label: {
                    Label("CropPrint Help", systemImage: "questionmark.circle")
                }
                .help("Open instructions for CropPrint.")
            }
        }
        .onChange(of: document.settings.preset) { _, preset in
            if preset.category == .monitor {
                document.settings.orientation = .landscape
            }
            document.resetCrop()
        }
        .onChange(of: document.settings.orientation) { _, _ in document.resetCrop() }
        .sheet(isPresented: $document.showsPrintSheetOptions) {
            if document.settings.preset.physicalInches != nil {
                let orientedSize = document.settings.preset.dimensions(
                    for: document.settings.orientation
                )
                PrintSheetOptionsView(
                    settings: $document.printSheetSettings,
                    photoSizeInches: orientedSize,
                    onCreate: document.createPrintSheet
                )
            }
        }
    }

    private var settingsPanel: some View {
        Form {
            Section("Photo") {
                Picker("Crop size", selection: $document.settings.preset) {
                    ForEach(PresetCategory.allCases) { category in
                        Section(category.rawValue) {
                            ForEach(CropPreset.allCases.filter { $0.category == category }) { preset in
                                Text(preset.title).tag(preset)
                            }
                        }
                    }
                }

                if document.settings.preset.supportsOrientation {
                    Picker("Orientation", selection: $document.settings.orientation) {
                        ForEach(PrintOrientation.allCases) { orientation in
                            Text(orientation.title).tag(orientation)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            if document.settings.isPrintPreset {
                Section("Paper") {
                Picker("Paper size", selection: $document.settings.paperSize) {
                    ForEach(PaperSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }

                Toggle("Add 0.25-inch white margin", isOn: $document.settings.includesMargin)

                if !document.settings.fitsPaper {
                    Label("The print size exceeds this paper size.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                }
            }

            Section("Output") {
                Text("Drag inside the rectangle to move it. Drag a corner handle to resize it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("The app saves a new file beside the original. It never changes the original file.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if document.settings.isPrintPreset && document.settings.includesMargin {
                    Text("The white margin stays inside the selected print size.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

            Spacer()

            Text(document.message)
                .font(.caption)
                .foregroundStyle(document.showsError ? .red : .secondary)
                .textSelection(.enabled)
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var canvas: some View {
        if let photo = document.photo {
            CropCanvas(
                photo: photo,
                normalizedCrop: $document.normalizedCrop,
                aspectRatio: document.settings.aspectRatio,
                decoration: $document.decoration,
                remoteFrame: remoteFrameImage
            )
            .padding(20)
            .background(Color(nsColor: .underPageBackgroundColor))
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted, perform: handleDrop)
        } else {
            ContentUnavailableView {
                Label("No Photo", systemImage: "photo")
            } description: {
                Text("Open a photo or drag one into this window.")
            } actions: {
                Button("Open Photo…") {
                    document.showOpenPanel()
                }
                .keyboardShortcut(.defaultAction)
            }
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first else { return false }
                document.open(url: url)
                return true
            }
        }
    }

    private var remoteFrameImage: Image? {
        guard let id = document.decoration.remoteFrameID,
              let url = resourceLibrary.cachedFileURL(for: id),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        return Image(nsImage: image)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else {
                url = item as? URL
            }
            if let url {
                Task { @MainActor in document.open(url: url) }
            }
        }
        return true
    }
}
