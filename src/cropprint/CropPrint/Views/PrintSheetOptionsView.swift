import SwiftUI

struct PrintSheetOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @AppStorage(DisplayCalibration.pointsPerInchKey)
    private var displayPointsPerInch = DisplayCalibration.defaultPointsPerInch
    @AppStorage(DisplayCalibration.completedKey)
    private var displayIsCalibrated = false
    @Binding var settings: PrintSheetSettings
    let photoSizeInches: CGSize
    let previewImage: CGImage?
    let onCreate: () -> Void
    @State private var showsTrueSizePreview = false

    private var layout: PrintSheetLayout? {
        try? PrintSheetLayout.make(photoSizeInches: photoSizeInches, settings: settings)
    }

    private var canCreate: Bool {
        #if os(macOS)
        layout != nil
        #else
        layout?.canRenderRaster(at: settings.resolution) == true
        #endif
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
                    Picker("JPEG image resolution", selection: $settings.resolution) {
                        ForEach(PrintSheetResolution.allCases) { resolution in
                            Text(resolution.title).tag(resolution)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Printer resolution", selection: $settings.printerResolution) {
                        ForEach(PrinterResolution.allCases) { resolution in
                            Text(resolution.title).tag(resolution)
                        }
                    }
                    .pickerStyle(.menu)

                    Text("Image PPI controls JPEG pixels. Printer DPI describes printer dots and does not change physical print dimensions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("Add cutting guides", isOn: $settings.includesCutGuides)
                }

                Section("Live size information") {
                    if let layout {
                        let rasterSize = layout.rasterPixelSize(at: settings.resolution)
                        LabeledContent("Printed photo") {
                            Text("\(formatted(photoSizeInches.width)) × \(formatted(photoSizeInches.height)) in")
                        }
                        LabeledContent("Paper") {
                            Text("\(formatted(layout.pageSizeInches.width)) × \(formatted(layout.pageSizeInches.height)) in")
                        }
                        LabeledContent("JPEG sheet") {
                            Text("\(Int(rasterSize.width)) × \(Int(rasterSize.height)) px")
                        }
                        LabeledContent("Printer page grid") {
                            let dpi = CGFloat(settings.printerResolution.rawValue)
                            Text("\(Int((layout.pageSizeInches.width * dpi).rounded())) × \(Int((layout.pageSizeInches.height * dpi).rounded())) dots")
                        }
                        if let bytes = layout.estimatedRasterBytes(at: settings.resolution) {
                            LabeledContent("Raster memory") {
                                Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .memory))
                            }
                        }
                        if let previewImage {
                            LabeledContent("Selected crop") {
                                Text("\(previewImage.width) × \(previewImage.height) px")
                            }
                            LabeledContent("Photo sampling") {
                                Text("\(effectivePhotoPPI(previewImage)) PPI")
                            }
                        }
                        LabeledContent("Display estimate") {
                            Text("\(formatted(displayPointsPerInch)) pt/in, \(formatted(displayPointsPerInch * Double(displayScale))) px/in")
                        }
                        LabeledContent("True-size screen area") {
                            Text("\(Int((photoSizeInches.width * CGFloat(displayPointsPerInch)).rounded())) × \(Int((photoSizeInches.height * CGFloat(displayPointsPerInch)).rounded())) pt")
                        }

                        Button("View True Size", systemImage: "ruler") {
                            showsTrueSizePreview = true
                        }
                        .disabled(previewImage == nil)

                        if !displayIsCalibrated {
                            Text("The display density is an estimate. Calibrate the true-size view against a physical ruler.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Section("Layout") {
                    if let layout {
                        Text("\(layout.copyCount) copies fit on this sheet.")
                        Text("Each copy is \(formatted(photoSizeInches.width)) × \(formatted(photoSizeInches.height)) inches.")
                        if !layout.canRenderRaster(at: settings.resolution) {
                            #if os(macOS)
                            Text("The JPEG exceeds the safe raster limit. CropPrint will create the resolution-independent PDF only.")
                                .foregroundStyle(.orange)
                            #else
                            Text("The JPEG exceeds the safe raster limit. Select lower image PPI or smaller paper.")
                                .foregroundStyle(.red)
                            #endif
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
            .sheet(isPresented: $showsTrueSizePreview) {
                if let previewImage {
                    TrueSizePreviewView(
                        previewImage: previewImage,
                        photoSizeInches: photoSizeInches
                    )
                }
            }
        }
        .modifier(PrintSheetPlatformFrame())
    }

    private func effectivePhotoPPI(_ image: CGImage) -> Int {
        let horizontal = CGFloat(image.width) / photoSizeInches.width
        let vertical = CGFloat(image.height) / photoSizeInches.height
        return Int(min(horizontal, vertical).rounded())
    }

    private func formatted(_ value: CGFloat) -> String {
        Double(value).formatted(.number.precision(.fractionLength(0...2)))
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

private enum DisplayCalibration {
    static let pointsPerInchKey = "CropPrint.trueSize.pointsPerInch"
    static let completedKey = "CropPrint.trueSize.isCalibrated"

    static var defaultPointsPerInch: Double {
        #if os(macOS)
        110
        #else
        UIDevice.current.userInterfaceIdiom == .pad ? 132 : 163
        #endif
    }
}

private struct TrueSizePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @AppStorage(DisplayCalibration.pointsPerInchKey)
    private var pointsPerInch = DisplayCalibration.defaultPointsPerInch
    @AppStorage(DisplayCalibration.completedKey)
    private var isCalibrated = false
    let previewImage: CGImage
    let photoSizeInches: CGSize

    private var previewSizePoints: CGSize {
        CGSize(
            width: photoSizeInches.width * CGFloat(pointsPerInch),
            height: photoSizeInches.height * CGFloat(pointsPerInch)
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("Printed size: \(formatted(photoSizeInches.width)) × \(formatted(photoSizeInches.height)) inches")
                    Text("Display: \(formatted(pointsPerInch)) points/inch · \(formatted(pointsPerInch * Double(displayScale))) pixels/inch")
                    Text("Screen area: \(Int(previewSizePoints.width.rounded())) × \(Int(previewSizePoints.height.rounded())) points")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                ScrollView([.horizontal, .vertical]) {
                    Image(decorative: previewImage, scale: 1)
                        .resizable()
                        .interpolation(.high)
                        .frame(
                            width: previewSizePoints.width,
                            height: previewSizePoints.height
                        )
                        .border(.secondary)
                        .padding(20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.06))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Display calibration")
                        .font(.headline)
                    Text("Place a physical ruler on the screen. Adjust the slider until this line measures exactly one inch.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(.primary)
                        .frame(width: CGFloat(pointsPerInch), height: 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Slider(value: $pointsPerInch, in: 50...240, step: 0.5)
                    Text("\(formatted(pointsPerInch)) points per inch")
                        .monospacedDigit()
                    HStack {
                        Button("Reset Estimate") {
                            pointsPerInch = DisplayCalibration.defaultPointsPerInch
                            isCalibrated = false
                        }
                        Button(isCalibrated ? "Calibrated" : "Use Calibration") {
                            isCalibrated = true
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("True-Size Preview")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .modifier(TrueSizePlatformFrame())
    }

    private func formatted(_ value: CGFloat) -> String {
        Double(value).formatted(.number.precision(.fractionLength(0...2)))
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

private struct PrintSheetPlatformFrame: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content.frame(minWidth: 520, minHeight: 620)
        #else
        content
        #endif
    }
}

private struct TrueSizePlatformFrame: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content.frame(minWidth: 640, minHeight: 620)
        #else
        content
        #endif
    }
}
