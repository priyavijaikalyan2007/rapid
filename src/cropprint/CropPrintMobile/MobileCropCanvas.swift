// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: d717d18a-0cbe-4d8d-a75e-9f935325568f
// Created: 2026
// COMPONENT: MobileCropCanvas
// PURPOSE: Composes the native MobileCropCanvas user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> MobileCropCanvas -> local result.

import SwiftUI

/// Composes the native MobileCropCanvas user interface.
struct MobileCropCanvas: View
{
    /// The selected local photo and its decoded source pixels.
    let photo: MobilePhoto
    /// Processed preview pixels when available, otherwise the unchanged source pixels.
    let displayImage: CGImage
    /// Crop rectangle in source-image coordinates normalized from zero through one.
    @Binding var normalizedCrop: CGRect
    let aspectRatio: CGFloat
    /// The passport guide value supplied to this MobileCropCanvas instance.
    let passportGuide: PassportGuide?
    /// Current decoration shared by the editor, preview, and export.
    @Binding var decoration: DecorationSettings
    let remoteFrame: Image?

    /// Drag start used by MobileCropCanvas.
    @State private var dragStart = CGRect.zero
    @State private var resizeStart = CGRect.zero

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        GeometryReader
        { proxy in
            let imageRect = CropGeometry.aspectFit(
                content: photo.pixelSize,
                in: CGRect(origin: .zero, size: proxy.size)
            )
            let cropRect = displayedCrop(in: imageRect)
            photoLayers(imageRect: imageRect, cropRect: cropRect)
        }
        .accessibilityLabel("Photo crop area")
        .accessibilityHint("Drag the crop rectangle to choose the part of the photo to keep.")
    }

    /// Builds a named resize control for the current selection.
    private func resizeHandle(for corner: CropCorner, cropRect: CGRect, imageRect: CGRect) -> some View
    {
        Circle().fill(.white)

            .frame(width: 22, height: 22)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
            .position(corner.point(in: cropRect))
            .gesture(resizeGesture(corner: corner, imageRect: imageRect))
            .accessibilityLabel("Resize \(corner.accessibilityName) corner")
            .accessibilityHint("Drag to resize the crop area without changing its aspect ratio.")
    }

    /// Places the draggable crop outline above the dimmed photo.
    private func cropSelection(imageRect: CGRect, cropRect: CGRect) -> some View
    {
        Rectangle().fill(.clear)
            .overlay
            {
                Rectangle().stroke(.white, lineWidth: 2)
            }
            .overlay
            {
                if passportGuide == nil
                {
                    MobileThirdsGrid().stroke(.white.opacity(0.55), lineWidth: 1)
                }
            }
            .frame(width: cropRect.width, height: cropRect.height)
            .position(x: cropRect.midX, y: cropRect.midY)
            .contentShape(Rectangle())
            .gesture(moveGesture(imageRect: imageRect))
    }

    /// Dims the image outside the selection without intercepting gestures.
    private func cropShade(imageRect: CGRect, cropRect: CGRect) -> some View
    {
        Path
        { path in path.addRect(imageRect)
            path.addRect(cropRect)
        }
        .fill(.black.opacity(0.6), style: FillStyle(eoFill: true))
        .allowsHitTesting(false)
    }

    /// Converts the normalized selection into coordinates inside the fitted image.
    private func displayedCrop(in imageRect: CGRect) -> CGRect
    {
        CGRect(
            x: imageRect.minX + normalizedCrop.minX * imageRect.width,
            y: imageRect.minY + normalizedCrop.minY * imageRect.height,
            width: normalizedCrop.width * imageRect.width,
            height: normalizedCrop.height * imageRect.height
        )
    }

    /// Composes photo, selection, guides, decorations, and accessible resize handles.
    private func photoLayers(imageRect: CGRect, cropRect: CGRect) -> some View
    {
        ZStack(alignment: .topLeading)
        {
            Color.black
            photoImage(in: imageRect)
            cropShade(imageRect: imageRect, cropRect: cropRect)
            cropSelection(imageRect: imageRect, cropRect: cropRect)
            cropOverlays(in: cropRect)
            ForEach(CropCorner.allCases, id: \.self)
            { corner in
                resizeHandle(for: corner, cropRect: cropRect, imageRect: imageRect)
            }
        }
    }

    /// Displays source pixels in the same fitted rectangle used for gesture math.
    private func photoImage(in imageRect: CGRect) -> some View
    {
        Image(decorative: displayImage, scale: 1, orientation: .up).resizable().aspectRatio(contentMode: .fit)
            .frame(width: imageRect.width, height: imageRect.height)
            .position(x: imageRect.midX, y: imageRect.midY)
    }

    /// Aligns optional passport guidance and editable decoration with the current selection.
    @ViewBuilder
    private func cropOverlays(in cropRect: CGRect) -> some View
    {
        if let passportGuide
        {
            PassportGuideOverlay(guide: passportGuide).frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
        }
        InteractiveDecorationOverlay(settings: $decoration, remoteFrame: remoteFrame)
            .frame(width: cropRect.width, height: cropRect.height).position(x: cropRect.midX, y: cropRect.midY)
            .coordinateSpace(name: "decorationCanvas")
    }

    /// Moves the selection using a stable drag origin.
    private func moveGesture(imageRect: CGRect) -> some Gesture
    {
        DragGesture().onChanged
        { value in
            guard imageRect.width > 0, imageRect.height > 0
            else
            {
                return
            }
            if dragStart == .zero
            {
                dragStart = normalizedCrop
            }
            let moved = dragStart.offsetBy(
                dx: value.translation.width / imageRect.width,
                dy: value.translation.height / imageRect.height
            )
            normalizedCrop = CropGeometry.clamp(moved, to: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        .onEnded
        { _ in
            dragStart = .zero
        }
    }

    /// Resizes around the opposite corner while preserving the selected aspect ratio.
    private func resizeGesture(corner: CropCorner, imageRect: CGRect) -> some Gesture
    {
        DragGesture(minimumDistance: 0)
            .onChanged
            { value in
                resizeSelection(value.translation, corner: corner, imageRect: imageRect)
            }
            .onEnded
            { _ in
                resizeStart = .zero
            }
    }

    /// Applies the minimum handle separation and bounds the selection inside the image.
    private func resizeSelection(_ translation: CGSize, corner: CropCorner, imageRect: CGRect)
    {
        guard imageRect.width > 0, imageRect.height > 0
        else
        {
            return
        }
        if resizeStart == .zero
        {
            resizeStart = normalizedCrop
        }
        let normalizedTranslation = CGSize(
            width: translation.width / imageRect.width,
            height: translation.height / imageRect.height
        )
        let minimumHeight = max(44 / imageRect.height, 44 / (aspectRatio * imageRect.height))
        normalizedCrop = CropGeometry.resizedCrop(
            from: resizeStart,
            corner: corner,
            normalizedTranslation: normalizedTranslation,
            imageSize: photo.pixelSize,
            aspectRatio: aspectRatio,
            minimumNormalizedHeight: minimumHeight
        )
    }
}
