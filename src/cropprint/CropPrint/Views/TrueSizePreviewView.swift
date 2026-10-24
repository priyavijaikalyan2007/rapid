// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 1a43b8f0-13b1-4dfc-b1d4-4b0e60ede208
// Created: 2026
// COMPONENT: TrueSizePreviewView
// PURPOSE: Composes the native TrueSizePreviewView user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> TrueSizePreviewView -> local result.

import SwiftUI

/// Composes the native TrueSizePreviewView user interface.
struct TrueSizePreviewView: View
{
    /// Dismiss used by TrueSizePreviewView.
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @AppStorage(DisplayCalibration.pointsPerInchKey)
    private var pointsPerInch = DisplayCalibration.defaultPointsPerInch
    /// Is calibrated used by TrueSizePreviewView.
    @AppStorage(DisplayCalibration.completedKey)
    private var isCalibrated = false
    /// The preview image value supplied to this TrueSizePreviewView instance.
    let previewImage: CGImage
    /// The photo size inches value supplied to this TrueSizePreviewView instance.
    let photoSizeInches: CGSize

    /// Preview size points used by TrueSizePreviewView.
    private var previewSizePoints: CGSize
    {
        CGSize(
            width: photoSizeInches.width * CGFloat(pointsPerInch),
            height: photoSizeInches.height * CGFloat(pointsPerInch)
        )
    }

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        NavigationStack
        {
            VStack(spacing: 12)
            {
                dimensionLabels
                    .font(.caption)
                    .foregroundStyle(.secondary)

                imageScrollView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.opacity(0.06))

                calibrationControls
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .navigationTitle("True-Size Preview")
            .toolbar
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
        .modifier(TrueSizePlatformFrame())
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

    /// Builds the dimension labels using the same local state.
    @ViewBuilder
    private var dimensionLabels: some View
    {
        VStack(spacing: 4)
        {
            Text(
                """
                Printed size: \(formatted(photoSizeInches.width)) × \(formatted(photoSizeInches.height)) \
                inches
                """
            )
            Text(
                """
                Display: \(formatted(pointsPerInch)) points/inch · \
                \(formatted(pointsPerInch * Double(displayScale))) pixels/inch
                """
            )
            Text(
                """
                Screen area: \(Int(previewSizePoints.width.rounded())) × \
                \(Int(previewSizePoints.height.rounded())) points
                """
            )
        }
    }

    /// Builds the image scroll view using the same local state.
    @ViewBuilder
    private var imageScrollView: some View
    {
        ScrollView([.horizontal, .vertical])
        {
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
    }

    /// Builds the calibration controls using the same local state.
    @ViewBuilder
    private var calibrationControls: some View
    {
        VStack(alignment: .leading, spacing: 8)
        {
            Text("Display calibration")
                .font(.headline)
            Text(
                """
                Place a physical ruler on the screen. Adjust the slider until this line measures exactly \
                one inch.
                """
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            Rectangle()
                .fill(.primary)
                .frame(width: CGFloat(pointsPerInch), height: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Slider(value: $pointsPerInch, in: 50 ... 240, step: 0.5)
            Text("\(formatted(pointsPerInch)) points per inch")
                .monospacedDigit()
            HStack
            {
                Button("Reset Estimate")
                {
                    pointsPerInch = DisplayCalibration.defaultPointsPerInch
                    isCalibrated = false
                }
                Button(isCalibrated ? "Calibrated" : "Use Calibration")
                {
                    isCalibrated = true
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
        }
    }
}
