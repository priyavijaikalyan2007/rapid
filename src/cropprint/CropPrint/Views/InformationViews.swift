import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct AboutCropPrintView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    private var gitSHA: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "CropPrintGitSHA") as? String
        guard let value, !value.isEmpty, !value.contains("$(") else { return "development" }
        return value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image("BrandIcon")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)

                Text("CropPrint")
                    .font(.largeTitle.bold())
            }

            Text("Version \(version)+\(gitSHA) (build \(buildNumber))")
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Text("CropPrint crops photos to exact print, social-media, phone, and display ratios. It never changes the original photo.")

            Text("Privacy")
                .font(.headline)

            Text("CropPrint has no login, analytics, advertising, or data collection. It contacts a server only when you refresh or download remote resources. The server receives normal request data, such as your Internet Protocol address.")

            Text("CropPrint is open-source software under the MIT License. Remote fonts and frames keep their own licenses.")

            Link("View the Privacy Policy", destination: URL(string: "https://outcrop.us/privacy/")!)

            Link("View the MIT License", destination: URL(string: "https://opensource.org/license/mit")!)

            Spacer()
        }
        .padding(24)
        .modifier(InformationPlatformFrame(minWidth: 420, minHeight: 360))
    }
}

struct CropPrintHelpView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Getting started") {
                    Text("1. Open a photo from the toolbar, File menu, Finder, or drag and drop.")
                    Text("2. Select a crop preset and orientation.")
                    Text("3. Move or resize the crop rectangle without changing its aspect ratio.")
                    Text("4. Select Crop and Save, or create a print sheet.")
                }

                Section("Toolbar icons") {
                    helpRow(
                        title: "Open Photo",
                        icon: "photo.badge.plus",
                        detail: "Open a photo from disk."
                    )
                    helpRow(
                        title: "Center Crop",
                        icon: "scope",
                        detail: "Center the crop rectangle at its largest size."
                    )
                    helpRow(
                        title: "Crop and Save",
                        icon: "crop",
                        detail: "Save the selected area as a new image beside the original."
                    )
                    helpRow(
                        title: "Create Print Sheet",
                        icon: "square.grid.2x2",
                        detail: "Tile physical-size copies on the selected paper."
                    )
                    helpRow(
                        title: "Help",
                        icon: "questionmark.circle",
                        detail: "Open this help page."
                    )
                }

                Section("Crop rectangle") {
                    Text("Drag inside the rectangle to move it.")
                    Text("Drag a corner handle to resize it. CropPrint keeps the selected aspect ratio.")
                    Text("Select Center Crop to restore the largest centered rectangle.")
                }

                Section("Passport photos") {
                    Text("Passport presets set the outer dimensions or required digital pixel size.")
                    Text("Check current government rules for head size, background, expression, image age, and file format.")
                }

                Section("Print sheets") {
                    Text("Select a physical print or passport preset before you create a print sheet.")
                    Text("Choose the paper, paper orientation, resolution, and cutting guides.")
                    Text("The macOS app saves JPEG and PDF files. The iPhone app saves the JPEG sheet to Photos.")
                    Text("Print at Actual Size or 100 percent. Disable Fit to Page and borderless enlargement.")
                }

                Section("Decorations") {
                    Text("Use the right sidebar to add text, colors, fonts, frames, opacity, and rotation.")
                    Text("CropPrint applies decorations to the saved crop and each print-sheet copy.")
                }

                Section("Files and privacy") {
                    Text("CropPrint never changes the original photo.")
                    Text("The macOS app saves new files beside the original. The iPhone app saves results to Photos.")
                    Text("Remote fonts and frames download only when you request them.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("CropPrint Help")
        }
        .modifier(HelpPlatformFrame())
    }

    private func helpRow(title: String, icon: String, detail: String) -> some View {
        LabeledContent {
            Text(detail)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        } label: {
            Label(title, systemImage: icon)
        }
    }
}

private struct HelpPlatformFrame: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content.frame(minWidth: 650, minHeight: 620)
        #else
        content
        #endif
    }
}

struct AttributionsView: View {
    @EnvironmentObject private var library: ResourceLibrary

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Each entry shows its title, creator, source, and exact license. CropPrint rejects incomplete entries and licenses that prohibit needed changes.")
                        .foregroundStyle(.secondary)
                }

                ForEach(RemoteResourceKind.allCases, id: \.self) { kind in
                    let items = library.resources.filter { $0.kind == kind }
                    if !items.isEmpty {
                        Section(kind.title + "s") {
                            ForEach(items) { resource in
                                attributionRow(resource)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Attributions")
        }
        .modifier(InformationPlatformFrame(minWidth: 560, minHeight: 440))
    }

    private func attributionRow(_ resource: RemoteResource) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(resource.name)
                    .font(.headline)
                if library.isDownloaded(resource) {
                    Label("Downloaded", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            Text("Creator: \(resource.creator)")
            HStack(spacing: 16) {
                Link("Source", destination: resource.sourceURL)
                Link(resource.licenseName, destination: resource.licenseURL)
            }
            .font(.caption)
            if let notes = resource.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ResourceLibraryView: View {
    @EnvironmentObject private var library: ResourceLibrary

    var body: some View {
        NavigationStack {
            Form {
                Section("Remote catalog") {
                    TextField("HTTPS catalog address", text: $library.catalogURLString)
                        .textContentType(.URL)

                    Button("Refresh Catalog") {
                        Task { await library.refreshCatalog() }
                    }

                    Text("Leave the address empty to use the built-in Google Fonts catalog.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(RemoteResourceKind.allCases, id: \.self) { kind in
                    let items = library.resources.filter { $0.kind == kind }
                    if !items.isEmpty {
                        Section(kind.title + "s") {
                            ForEach(items) { resource in
                                resourceRow(resource)
                            }
                        }
                    }
                }

                Section("Status") {
                    Text(library.status)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Remote Resources")
        }
        .modifier(InformationPlatformFrame(minWidth: 560, minHeight: 480))
    }

    private func resourceRow(_ resource: RemoteResource) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(resource.name)
                    .font(.headline)
                Text("\(resource.creator) · \(resource.licenseName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if library.isDownloaded(resource) {
                Label("Downloaded", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Download") {
                    Task { await library.download(resource) }
                }
                .disabled(library.activeDownloads.contains(resource.id))
            }
        }
    }
}

struct DecorationEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: ResourceLibrary
    @Binding var settings: DecorationSettings
    var showsDoneButton = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Text") {
                    Text("Drag the text box to move it. Use the side circle to change its width. Use the corner square to scale it. Use the blue handle to rotate it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("Text", text: $settings.text, axis: .vertical)
                        .lineLimit(1...3)

                    Picker("Font", selection: $settings.fontName) {
                        Text("Helvetica Neue Bold").tag("HelveticaNeue-Bold")
                        Text("Avenir Next Bold").tag("AvenirNext-Bold")
                        Text("Georgia Bold").tag("Georgia-Bold")
                        ForEach(library.availableFonts, id: \.fontName) { font in
                            Text(font.name).tag(font.fontName)
                        }
                    }

                    Picker("Style", selection: $settings.textStyle) {
                        ForEach(TextDecorationStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }

                    LabeledContent("Color") {
                        HStack(spacing: 8) {
                            ForEach(DecorationColor.allCases) { color in
                                Button {
                                    settings.textColor = color
                                    settings.usesCustomTextColor = false
                                } label: {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 22, height: 22)
                                        .overlay {
                                            Circle().stroke(
                                                settings.textColor == color && !settings.usesCustomTextColor
                                                    ? Color.accentColor
                                                    : Color.secondary.opacity(0.45),
                                                lineWidth: settings.textColor == color && !settings.usesCustomTextColor ? 3 : 1
                                            )
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(color.title)
                            }
                        }
                    }

                    ColorPicker(
                        "Custom color",
                        selection: customTextColor,
                        supportsOpacity: false
                    )

                    LabeledContent("Size", value: "\(Int(settings.textSize * 100))%")
                    Slider(value: $settings.textSize, in: 0.025...0.25)

                    LabeledContent("Opacity", value: "\(Int(settings.textOpacity * 100))%")
                    Slider(value: $settings.textOpacity, in: 0.1...1)

                    LabeledContent("Rotation", value: "\(Int(settings.textRotation))°")
                    Slider(value: $settings.textRotation, in: -180...180, step: 1)

                    LabeledContent("Horizontal position", value: "\(Int(settings.textX * 100))%")
                    Slider(value: $settings.textX, in: 0.05...0.95)

                    LabeledContent("Vertical position", value: "\(Int(settings.textY * 100))%")
                    Slider(value: $settings.textY, in: 0.05...0.95)
                }

                Section("Frame") {
                    Picker("Style", selection: $settings.frameStyle) {
                        ForEach(PhotoFrameStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }

                    LabeledContent("Color") {
                        HStack(spacing: 8) {
                            ForEach(DecorationColor.allCases) { color in
                                Button {
                                    settings.frameColor = color
                                    settings.usesCustomFrameColor = false
                                } label: {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 22, height: 22)
                                        .overlay {
                                            Circle().stroke(
                                                settings.frameColor == color && !settings.usesCustomFrameColor
                                                    ? Color.accentColor
                                                    : Color.secondary.opacity(0.45),
                                                lineWidth: settings.frameColor == color && !settings.usesCustomFrameColor ? 3 : 1
                                            )
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(color.title)
                            }
                        }
                    }

                    ColorPicker(
                        "Custom color",
                        selection: customFrameColor,
                        supportsOpacity: false
                    )

                    LabeledContent("Width", value: "\(Int(settings.frameWidth * 100))%")
                    Slider(value: $settings.frameWidth, in: 0.005...0.12)

                    LabeledContent("Opacity", value: "\(Int(settings.frameOpacity * 100))%")
                    Slider(value: $settings.frameOpacity, in: 0.1...1)

                    Picker("Downloaded frame", selection: $settings.remoteFrameID) {
                        Text("None").tag(nil as String?)
                        ForEach(library.availableFrames) { frame in
                            Text(frame.name).tag(frame.id as String?)
                        }
                    }

                    if library.availableFrames.isEmpty {
                        Text("Download a frame from Remote Resources to add it here.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Remove All Decorations", role: .destructive) {
                        settings = DecorationSettings()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Decorate")
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
        .modifier(DecorationEditorPlatformFrame(showsDoneButton: showsDoneButton))
    }

    private var customTextColor: Binding<Color> {
        Binding {
            settings.resolvedTextColor
        } set: { color in
#if os(macOS)
            let converted = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
            settings.customTextRed = converted.redComponent
            settings.customTextGreen = converted.greenComponent
            settings.customTextBlue = converted.blueComponent
#else
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            settings.customTextRed = red
            settings.customTextGreen = green
            settings.customTextBlue = blue
#endif
            settings.usesCustomTextColor = true
        }
    }

    private var customFrameColor: Binding<Color> {
        Binding {
            settings.resolvedFrameColor
        } set: { color in
#if os(macOS)
            let converted = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
            settings.customFrameRed = converted.redComponent
            settings.customFrameGreen = converted.greenComponent
            settings.customFrameBlue = converted.blueComponent
#else
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            settings.customFrameRed = red
            settings.customFrameGreen = green
            settings.customFrameBlue = blue
#endif
            settings.usesCustomFrameColor = true
        }
    }
}

private struct DecorationEditorPlatformFrame: ViewModifier {
    let showsDoneButton: Bool

    func body(content: Content) -> some View {
        #if os(macOS)
        content.frame(
            minWidth: showsDoneButton ? 520 : 280,
            minHeight: 620
        )
        #else
        content.frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}

private struct InformationPlatformFrame: ViewModifier {
    let minWidth: CGFloat
    let minHeight: CGFloat

    func body(content: Content) -> some View {
        #if os(macOS)
        content.frame(minWidth: minWidth, minHeight: minHeight)
        #else
        content
        #endif
    }
}
