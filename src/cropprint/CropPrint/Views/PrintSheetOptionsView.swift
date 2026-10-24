// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4c9536bb-58a4-4e6a-b7f0-9061577e9627
// Created: 2026
// COMPONENT: PrintSheetOptionsView
// PURPOSE: Composes the native PrintSheetOptionsView user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PrintSheetOptionsView -> local result.

import SwiftUI

/// Composes the native PrintSheetOptionsView user interface.
struct PrintSheetOptionsView: View
{
    /// Dismiss used by PrintSheetOptionsView.
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @AppStorage(DisplayCalibration.pointsPerInchKey)
    private var displayPointsPerInch = DisplayCalibration.defaultPointsPerInch
    /// Display is calibrated used by PrintSheetOptionsView.
    @AppStorage(DisplayCalibration.completedKey)
    private var displayIsCalibrated = false
    /// Current settings shared by the editor, preview, and export.
    @Binding var settings: PrintSheetSettings
    let photoSizeInches: CGSize
    /// The preview image value supplied to this PrintSheetOptionsView instance.
    let previewImage: CGImage?
    /// The on create value supplied to this PrintSheetOptionsView instance.
    let onCreate: () -> Void
    /// Shows true size preview used by PrintSheetOptionsView.
    @State private var showsTrueSizePreview = AppStoreScreenshotScenario.current == .trueSize

    /// Layout used by PrintSheetOptionsView.
    private var layout: PrintSheetLayout?
    {
        try? PrintSheetLayout.make(photoSizeInches: photoSizeInches, settings: settings)
    }

    /// Can create used by PrintSheetOptionsView.
    private var canCreate: Bool
    {
        #if os(macOS)
        layout != nil
        #else
        layout?.canRenderRaster(at: settings.resolution) == true
        #endif
    }

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        NavigationStack
        {
            sheetForm
                .formStyle(.grouped)
                .navigationTitle("Create Print Sheet")
                .toolbar
                {
                    cancelToolbarItem
                    createToolbarItem
                }
                .sheet(isPresented: $showsTrueSizePreview)
                {
                    if let previewImage
                    {
                        TrueSizePreviewView(
                            previewImage: previewImage,
                            photoSizeInches: photoSizeInches
                        )
                    }
                }
        }
        .modifier(PrintSheetPlatformFrame())
    }

    /// Returns the source sampling density at the selected physical print size.
    private func effectivePhotoPPI(_ image: CGImage) -> Int
    {
        let horizontal = CGFloat(image.width) / photoSizeInches.width
        let vertical = CGFloat(image.height) / photoSizeInches.height
        return Int(min(horizontal, vertical).rounded())
    }

    /// Formats a size label with bounded decimal precision for the current locale.
    private func formatted(_ value: CGFloat) -> String
    {
        Double(value).formatted(.number.precision(.fractionLength(0 ... 2)))
    }

    /// Formats a size label with bounded decimal precision for the current locale.
    private func formatted(_ value: Double) -> String
    {
        value.formatted(.number.precision(.fractionLength(0 ... 1)))
    }

    /// Builds the paper picker using the same local state.
    @ViewBuilder
    private var paperPicker: some View
    {
        Picker("Paper size", selection: $settings.paperSize)
        {
            ForEach(PaperSize.allCases)
            { paper in
                Text(paper.rawValue).tag(paper)
            }
        }
    }

    /// Builds the orientation picker using the same local state.
    @ViewBuilder
    private var orientationPicker: some View
    {
        Picker("Paper orientation", selection: $settings.paperOrientation)
        {
            ForEach(PrintOrientation.allCases)
            { orientation in
                Text(orientation.title).tag(orientation)
            }
        }
    }

    /// Builds the image resolution picker using the same local state.
    @ViewBuilder
    private var imageResolutionPicker: some View
    {
        Picker("JPEG image resolution", selection: $settings.resolution)
        {
            ForEach(PrintSheetResolution.allCases)
            { resolution in
                Text(resolution.title).tag(resolution)
            }
        }
    }

    /// Builds the printer resolution picker using the same local state.
    @ViewBuilder
    private var printerResolutionPicker: some View
    {
        Picker("Printer resolution", selection: $settings.printerResolution)
        {
            ForEach(PrinterResolution.allCases)
            { resolution in
                Text(resolution.title).tag(resolution)
            }
        }
    }

    /// Builds the paper section using the same local state.
    @ViewBuilder
    private var paperSection: some View
    {
        Section("Paper")
        {
            paperPicker

            orientationPicker
                .pickerStyle(.segmented)
        }
    }

    /// Builds the output section using the same local state.
    @ViewBuilder
    private var outputSection: some View
    {
        Section("Output")
        {
            imageResolutionPicker
                .pickerStyle(.menu)

            printerResolutionPicker
                .pickerStyle(.menu)

            Text(
                """
                Image PPI controls JPEG pixels. Printer DPI describes printer dots and does not change \
                physical print dimensions.
                """
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Toggle("Add cutting guides", isOn: $settings.includesCutGuides)
        }
    }

    /// Builds the live size section using the same local state.
    @ViewBuilder
    private var liveSizeSection: some View
    {
        Section("Live size information")
        {
            if let layout
            {
                printedPhotoRow
                paperRow(layout: layout)
                jpegRow(layout: layout)
                printerGridRow(layout: layout)
                memoryRow(layout: layout)
                previewRows
                displayEstimateRow
                screenAreaRow

                Button("View True Size", systemImage: "ruler")
                {
                    showsTrueSizePreview = true
                }
                .disabled(previewImage == nil)

                calibrationNotice
            }
        }
    }

    /// Builds the layout section using the same local state.
    @ViewBuilder
    private var layoutSection: some View
    {
        Section("Layout")
        {
            if let layout
            {
                Text("\(layout.copyCount) copies fit on this sheet.")
                Text(
                    """
                    Each copy is \(formatted(photoSizeInches.width)) × \
                    \(formatted(photoSizeInches.height)) inches.
                    """
                )
                rasterLimitNotice(layout: layout)
            }
            else
            {
                Text("The selected photo size does not fit on this paper.")
                    .foregroundStyle(.red)
            }

            #if os(macOS)
            Text(
                """
                Print the PDF at Actual Size or 100 percent. Disable Fit to Page and automatic borderless \
                enlargement.
                """
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            #else
            Text(
                """
                Print the saved sheet at Actual Size or 100 percent. Disable Fit to Page and automatic \
                borderless enlargement.
                """
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            #endif
        }
    }

    /// Builds the sheet form using the same local state.
    @ViewBuilder
    private var sheetForm: some View
    {
        Form
        {
            paperSection

            outputSection

            liveSizeSection

            layoutSection
        }
    }

    /// Builds the cancel toolbar item using the same local state.
    @ToolbarContentBuilder
    private var cancelToolbarItem: some ToolbarContent
    {
        ToolbarItem(placement: .cancellationAction)
        {
            Button("Cancel")
            {
                dismiss()
            }
        }
    }

    /// Builds the create toolbar item using the same local state.
    @ToolbarContentBuilder
    private var createToolbarItem: some ToolbarContent
    {
        ToolbarItem(placement: .confirmationAction)
        {
            Button("Create")
            {
                onCreate()
                dismiss()
            }
            .disabled(!canCreate)
        }
    }

    /// Builds the printed photo row using the same local state.
    @ViewBuilder
    private var printedPhotoRow: some View
    {
        LabeledContent("Printed photo")
        {
            Text("\(formatted(photoSizeInches.width)) × \(formatted(photoSizeInches.height)) in")
        }
    }

    /// Builds the paper row using the same local state.
    @ViewBuilder
    private func paperRow(layout: PrintSheetLayout) -> some View
    {
        LabeledContent("Paper")
        {
            Text(
                """
                \(formatted(layout.pageSizeInches.width)) × \
                \(formatted(layout.pageSizeInches.height)) in
                """
            )
        }
    }

    /// Builds the jpeg row using the same local state.
    @ViewBuilder
    private func jpegRow(layout: PrintSheetLayout) -> some View
    {
        let rasterSize = layout.rasterPixelSize(at: settings.resolution)
        LabeledContent("JPEG sheet")
        {
            Text("\(Int(rasterSize.width)) × \(Int(rasterSize.height)) px")
        }
    }

    /// Builds the printer grid row using the same local state.
    @ViewBuilder
    private func printerGridRow(layout: PrintSheetLayout) -> some View
    {
        LabeledContent("Printer page grid")
        {
            let dpi = CGFloat(settings.printerResolution.rawValue)
            Text(
                """
                \(Int((layout.pageSizeInches.width * dpi).rounded())) × \
                \(Int((layout.pageSizeInches.height * dpi).rounded())) dots
                """
            )
        }
    }

    /// Builds the display estimate row using the same local state.
    @ViewBuilder
    private var displayEstimateRow: some View
    {
        LabeledContent("Display estimate")
        {
            Text(
                """
                \(formatted(displayPointsPerInch)) pt/in, \
                \(formatted(displayPointsPerInch * Double(displayScale))) px/in
                """
            )
        }
    }

    /// Builds the screen area row using the same local state.
    @ViewBuilder
    private var screenAreaRow: some View
    {
        LabeledContent("True-size screen area")
        {
            Text(
                """
                \(Int((photoSizeInches.width * CGFloat(displayPointsPerInch)).rounded())) × \
                \(Int((photoSizeInches.height * CGFloat(displayPointsPerInch)).rounded())) pt
                """
            )
        }
    }

    /// Builds the preview rows using the same local state.
    @ViewBuilder
    private var previewRows: some View
    {
        if let previewImage
        {
            LabeledContent("Selected crop")
            {
                Text("\(previewImage.width) × \(previewImage.height) px")
            }
            LabeledContent("Photo sampling")
            {
                Text("\(effectivePhotoPPI(previewImage)) PPI")
            }
        }
    }

    /// Builds the calibration notice using the same local state.
    @ViewBuilder
    private var calibrationNotice: some View
    {
        if !displayIsCalibrated
        {
            Text(
                """
                The display density is an estimate. Calibrate the true-size view against a \
                physical ruler.
                """
            )
            .font(.caption)
            .foregroundStyle(.orange)
        }
    }

    /// Builds the raster limit notice using the same local state.
    @ViewBuilder
    private func rasterLimitNotice(layout: PrintSheetLayout) -> some View
    {
        if !layout.canRenderRaster(at: settings.resolution)
        {
            #if os(macOS)
            Text(
                """
                The JPEG exceeds the safe raster limit. CropPrint will create the \
                resolution-independent PDF only.
                """
            )
            .foregroundStyle(.orange)
            #else
            Text("The JPEG exceeds the safe raster limit. Select lower image PPI or smaller paper.")
                .foregroundStyle(.red)
            #endif
        }
    }

    /// Builds the memory row using the same local state.
    @ViewBuilder
    private func memoryRow(layout: PrintSheetLayout) -> some View
    {
        if let bytes = layout.estimatedRasterBytes(at: settings.resolution)
        {
            LabeledContent("Raster memory")
            {
                Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .memory))
            }
        }
    }
}
