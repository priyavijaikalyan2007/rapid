// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 6f63b365-b35d-4aeb-8ed6-34d659e9b7c3
// Created: 2026
// COMPONENT: CropPrintHelpView
// PURPOSE: Composes the native CropPrintHelpView user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> CropPrintHelpView -> local result.

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Composes the native CropPrintHelpView user interface.
struct CropPrintHelpView: View
{
    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        NavigationStack
        {
            Form
            {
                gettingStartedSection

                toolbarIconsSection

                cropRectangleSection

                passportPhotosSection

                photoAdjustmentsSection

                printSheetsSection

                decorationsSection

                filesAndPrivacySection

                supportSection
            }
            .formStyle(.grouped)
            .navigationTitle("CropPrint Help")
        }
        .modifier(HelpPlatformFrame())
    }

    /// Pairs a native symbol with its action name and usage instructions.
    private func helpRow(title: String, icon: String, detail: String) -> some View
    {
        LabeledContent
        {
            Text(detail)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        } label: {
            Label(title, systemImage: icon)
        }
    }

    /// Builds the getting started section using the same local state.
    @ViewBuilder
    private var gettingStartedSection: some View
    {
        Section("Getting started")
        {
            Text("1. Open a photo from the toolbar, File menu, Finder, or drag and drop.")
            Text("2. Select a crop preset and orientation.")
            Text("3. Move or resize the crop rectangle without changing its aspect ratio.")
            Text("4. Select Crop and Save, or create a print sheet.")
        }
    }

    /// Builds the toolbar icons section using the same local state.
    @ViewBuilder
    private var toolbarIconsSection: some View
    {
        Section("Toolbar icons")
        {
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
    }

    /// Builds the crop rectangle section using the same local state.
    @ViewBuilder
    private var cropRectangleSection: some View
    {
        Section("Crop rectangle")
        {
            Text("Drag inside the rectangle to move it.")
            Text("Drag a corner handle to resize it. CropPrint keeps the selected aspect ratio.")
            Text("Select Center Crop to restore the largest centered rectangle.")
        }
    }

    /// Builds the passport photos section using the same local state.
    @ViewBuilder
    private var passportPhotosSection: some View
    {
        Section("Passport photos")
        {
            Text("Passport presets set the outer dimensions or required digital pixel size.")
            Text(
                """
                Enable the passport guide to align the top of the head and the chin with the translucent \
                bands.
                """
            )
            Text("Open the linked government page because passport rules can change.")
            Text(
                """
                Check current government rules for head size, background, expression, image age, and file \
                format.
                """
            )
        }
    }

    /// Builds the photo adjustments section using the same local state.
    @ViewBuilder
    private var photoAdjustmentsSection: some View
    {
        Section("Photo adjustments")
        {
            Text(
                """
                Use Photo Adjustments to change exposure, contrast, highlights, shadows, saturation, hue, \
                sharpness, and angle.
                """
            )
            Text("Background replacement uses Apple person segmentation and runs only on this device.")
            Text("Some passport authorities reject background replacement or other digital edits.")
            Text("Reset Photo Edits restores the loaded photo without changing the original file.")
        }
    }

    /// Builds the print sheets section using the same local state.
    @ViewBuilder
    private var printSheetsSection: some View
    {
        Section("Print sheets")
        {
            Text("Select a physical print or passport preset before you create a print sheet.")
            Text("Choose the paper, orientation, image PPI, printer DPI, and cutting guides.")
            Text("Select View True Size to calibrate the display and inspect the printed dimensions on screen.")
            Text(
                """
                The live size section shows crop pixels, photo sampling, sheet pixels, and estimated \
                raster memory.
                """
            )
            Text("The macOS app saves JPEG and PDF files. The iOS app saves the JPEG sheet to Photos.")
            Text("Print at Actual Size or 100 percent. Disable Fit to Page and borderless enlargement.")
        }
    }

    /// Builds the decorations section using the same local state.
    @ViewBuilder
    private var decorationsSection: some View
    {
        Section("Decorations")
        {
            Text("Use the right sidebar to add text, colors, fonts, frames, opacity, and rotation.")
            Text("CropPrint applies decorations to the saved crop and each print-sheet copy.")
        }
    }

    /// Builds the files and privacy section using the same local state.
    @ViewBuilder
    private var filesAndPrivacySection: some View
    {
        Section("Files and privacy")
        {
            Text("CropPrint never changes the original photo.")
            Text("The macOS app saves new files beside the original. The iOS app saves results to Photos.")
            Text("Photo adjustments and background replacement run locally.")
            Text("Remote fonts and frames download only when you request them.")
        }
    }

    /// Builds the support section using the same local state.
    @ViewBuilder
    private var supportSection: some View
    {
        Section("Support")
        {
            Text("CropPrint provides support only through the public GitHub issue tracker.")
            Link(
                "Report an Issue",
                destination: URL(string: "https://github.com/priyavijaikalyan2007/rapid/issues/new/choose")!
            )
            Text("Do not attach a private photo. Use a test photo or remove private details first.")
        }
    }
}
