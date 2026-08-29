import SwiftUI

struct PrintSheetOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var settings: PrintSheetSettings
    let photoSizeInches: CGSize
    let onCreate: () -> Void

    private var layout: PrintSheetLayout? {
        try? PrintSheetLayout.make(photoSizeInches: photoSizeInches, settings: settings)
    }

    private var canCreate: Bool {
        layout?.canRenderRaster(at: settings.resolution) == true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Paper") {
                    Picker("Paper size", selection: $settings.paperSize) {
                        ForEach(PaperSize.allCases) { paper in
                            Text(paper.rawValue).tag(paper)
                        }
                    }

                    Picker("Paper orientation", selection: $settings.paperOrientation) {
                        ForEach(PrintOrientation.allCases) { orientation in
                            Text(orientation.title).tag(orientation)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Output") {
                    Picker("Resolution", selection: $settings.resolution) {
                        ForEach(PrintSheetResolution.allCases) { resolution in
                            Text(resolution.title).tag(resolution)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Add cutting guides", isOn: $settings.includesCutGuides)
                }

                Section("Layout") {
                    if let layout {
                        Text("\(layout.copyCount) copies fit on this sheet.")
                        Text("Each copy is \(formatted(photoSizeInches.width)) × \(formatted(photoSizeInches.height)) inches.")
                        if !layout.canRenderRaster(at: settings.resolution) {
                            Text("This resolution is too large for the selected paper. Select 300 PPI or smaller paper.")
                                .foregroundStyle(.red)
                        }
                    } else {
                        Text("The selected photo size does not fit on this paper.")
                            .foregroundStyle(.red)
                    }

                    #if os(macOS)
                    Text("Print the PDF at Actual Size or 100 percent. Disable Fit to Page and automatic borderless enlargement.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #else
                    Text("Print the saved sheet at Actual Size or 100 percent. Disable Fit to Page and automatic borderless enlargement.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #endif
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Create Print Sheet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate()
                        dismiss()
                    }
                    .disabled(!canCreate)
                }
            }
        }
        .modifier(PrintSheetPlatformFrame())
    }

    private func formatted(_ value: CGFloat) -> String {
        Double(value).formatted(.number.precision(.fractionLength(0...3)))
    }
}

private struct PrintSheetPlatformFrame: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content.frame(minWidth: 430, minHeight: 440)
        #else
        content
        #endif
    }
}
