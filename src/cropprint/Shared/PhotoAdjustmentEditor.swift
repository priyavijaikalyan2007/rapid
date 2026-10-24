// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 6b4e2c28-8ace-48a5-ae0d-a91ed5734461
// Created: 2026
// COMPONENT: PhotoAdjustmentEditor
// PURPOSE: Composes the native PhotoAdjustmentEditor user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PhotoAdjustmentEditor -> local result.

import SwiftUI

/// Composes the native PhotoAdjustmentEditor user interface.
struct PhotoAdjustmentEditor: View
{
    /// Current settings shared by the editor, preview, and export.
    @Binding var settings: PhotoAdjustmentSettings
    let allowsBackgroundRemoval: Bool
    /// The is passport photo value supplied to this PhotoAdjustmentEditor instance.
    let isPassportPhoto: Bool
    /// The is processing value supplied to this PhotoAdjustmentEditor instance.
    let isProcessing: Bool
    /// Shows done button used by PhotoAdjustmentEditor.
    var showsDoneButton = false

    /// Dismiss used by PhotoAdjustmentEditor.
    @Environment(\.dismiss) private var dismiss

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        editorForm
            .formStyle(.grouped)
            .navigationTitle("Photo Adjustments")
            .toolbar
            {
                if showsDoneButton
                {
                    ToolbarItem(placement: .confirmationAction)
                    {
                        Button("Done")
                        {
                            dismiss()
                        }
                    }
                }
            }
    }

    /// Builds a named native slider and displays its current adjustment value.
    private func adjustmentSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        suffix: String = ""
    ) -> some View
    {
        VStack(alignment: .leading, spacing: 4)
        {
            HStack
            {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(1))) + suffix)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range)
        }
    }

    /// Builds the background picker using the same local state.
    @ViewBuilder
    private var backgroundPicker: some View
    {
        Picker("Replace background", selection: $settings.background)
        {
            ForEach(ReplacementBackground.allCases)
            { background in
                Text(background.rawValue).tag(background)
            }
        }
    }

    /// Builds the background section using the same local state.
    @ViewBuilder
    private var backgroundSection: some View
    {
        Section("Background")
        {
            backgroundPicker

            Text("Person separation runs on this device. The photo does not leave the device.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if isPassportPhoto && settings.background != .original
            {
                Label(
                    """
                    Some passport authorities reject digitally replaced backgrounds. Check the current \
                    official rules before submission.
                    """,
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
    }

    /// Builds the tone section using the same local state.
    @ViewBuilder
    private var toneSection: some View
    {
        Section("Light and color")
        {
            adjustmentSlider("Exposure", value: $settings.exposure, range: -2 ... 2)
            adjustmentSlider("Contrast", value: $settings.contrast, range: 0.5 ... 1.5)
            adjustmentSlider("Highlights", value: $settings.highlights, range: -1 ... 1)
            adjustmentSlider("Shadows", value: $settings.shadows, range: -1 ... 1)
            adjustmentSlider("Saturation", value: $settings.saturation, range: 0 ... 2)
            adjustmentSlider("Hue", value: $settings.hue, range: -180 ... 180, suffix: "°")
            adjustmentSlider("Sharpness", value: $settings.sharpness, range: 0 ... 1)
        }
    }

    /// Builds the straighten section using the same local state.
    @ViewBuilder
    private var straightenSection: some View
    {
        Section("Straighten")
        {
            adjustmentSlider("Angle", value: $settings.angle, range: -15 ... 15, suffix: "°")
            Text("Angle adjustment enlarges the photo enough to avoid empty corners.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Builds the passport edit warning using the same local state.
    @ViewBuilder
    private var passportEditWarning: some View
    {
        if isPassportPhoto && settings.hasToneChanges
        {
            Section
            {
                Label(
                    "Passport authorities can reject altered photos. Use edits only to correct the captured image.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
    }

    /// Builds the reset section using the same local state.
    @ViewBuilder
    private var resetSection: some View
    {
        Section
        {
            Button("Reset Photo Edits", role: .destructive)
            {
                settings = PhotoAdjustmentSettings()
            }
            .disabled(settings.isDefault)

            if isProcessing
            {
                HStack
                {
                    ProgressView()
                    Text("Applying local photo edits…")
                }
            }
        }
    }

    /// Builds the editor form using the same local state.
    @ViewBuilder
    private var editorForm: some View
    {
        Form
        {
            if allowsBackgroundRemoval
            {
                backgroundSection
            }

            toneSection

            straightenSection

            passportEditWarning

            resetSection
        }
    }
}
