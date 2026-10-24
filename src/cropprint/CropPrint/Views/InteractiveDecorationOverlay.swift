// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b4c5981d-4673-4fe2-8d39-9d773a296798
// Created: 2026
// COMPONENT: InteractiveDecorationOverlay
// PURPOSE: Composes the native InteractiveDecorationOverlay user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> InteractiveDecorationOverlay -> local result.

import SwiftUI

/// Composes the native InteractiveDecorationOverlay user interface.
struct InteractiveDecorationOverlay: View
{
    /// Current settings shared by the editor, preview, and export.
    @Binding var settings: DecorationSettings
    let remoteFrame: Image?

    /// Move start used by InteractiveDecorationOverlay.
    @State private var moveStart: CGPoint?
    @State private var resizeStart: (width: CGFloat, size: CGFloat)?
    @State private var widthStart: CGFloat?

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        GeometryReader
        { proxy in
            let canvasSize = proxy.size

            DecorationOverlay(settings: frameOnlySettings, remoteFrame: remoteFrame)

            if settings.hasText
            {
                editableText(in: canvasSize)
            }
        }
        .clipped()
    }

    /// Frame only settings used by InteractiveDecorationOverlay.
    private var frameOnlySettings: DecorationSettings
    {
        var value = settings
        value.text = ""
        return value
    }

    /// Places local text with handles for movement, width, scale, and rotation.
    private func editableText(in canvasSize: CGSize) -> some View
    {
        let minimumDimension = min(canvasSize.width, canvasSize.height)
        let fontSize = max(8, minimumDimension * settings.textSize)
        let boxWidth = max(70, canvasSize.width * settings.textBoxWidth)

        return textControls(styledText(fontSize: fontSize, boxWidth: boxWidth), canvasSize: canvasSize)
            .rotationEffect(.degrees(settings.textRotation))
            .position(
                x: canvasSize.width * settings.textX,
                y: canvasSize.height * settings.textY
            )
            .contentShape(Rectangle())
            .gesture(moveGesture(canvasSize: canvasSize))
    }

    /// Updates the normalized text position from a stable drag origin.
    private func moveGesture(canvasSize: CGSize) -> some Gesture
    {
        DragGesture()
            .onChanged
            { value in
                if moveStart == nil
                {
                    moveStart = CGPoint(x: settings.textX, y: settings.textY)
                }
                guard let moveStart
                else
                {
                    return
                }
                settings.textX = min(0.98, max(0.02, moveStart.x + value.translation.width / canvasSize.width))
                settings.textY = min(0.98, max(0.02, moveStart.y + value.translation.height / canvasSize.height))
            }
            .onEnded
            { _ in
                moveStart = nil
            }
    }

    /// Changes the text box width within the supported normalized range.
    private func widthHandle(canvasSize: CGSize) -> some View
    {
        Circle()
            .fill(.white)
            .overlay
            {
                Circle().stroke(.black.opacity(0.7), lineWidth: 1)
            }
            .frame(width: 18, height: 18)
            .contentShape(Circle().inset(by: -10))
            .gesture(widthGesture(canvasSize: canvasSize))
            .accessibilityLabel("Resize text box width")
    }

    /// Builds a named resize control for the current selection.
    private func resizeHandle(canvasSize: CGSize) -> some View
    {
        RoundedRectangle(cornerRadius: 3)
            .fill(.white)
            .overlay
            {
                RoundedRectangle(cornerRadius: 3).stroke(.black.opacity(0.7), lineWidth: 1)
            }
            .frame(width: 18, height: 18)
            .contentShape(Rectangle().inset(by: -10))
            .gesture(resizeGesture(canvasSize: canvasSize))
            .accessibilityLabel("Scale text box")
    }

    /// Maps the drag angle around the text center to degrees of rotation.
    private func rotationHandle(canvasSize: CGSize) -> some View
    {
        VStack(spacing: 0)
        {
            Circle()
                .fill(.blue)
                .overlay
                {
                    Circle().stroke(.white, lineWidth: 2)
                }
                .frame(width: 20, height: 20)
            Rectangle()
                .fill(.white)
                .frame(width: 1, height: 18)
        }
        .contentShape(Rectangle().inset(by: -8))
        .gesture(rotationGesture(canvasSize: canvasSize))
        .accessibilityLabel("Rotate text box")
    }

    /// Applies the width drag interaction without retaining image content.
    private func widthGesture(canvasSize: CGSize) -> some Gesture
    {
        DragGesture(minimumDistance: 0)
            .onChanged
            { value in
                if widthStart == nil
                {
                    widthStart = settings.textBoxWidth
                }
                guard let widthStart
                else
                {
                    return
                }
                settings.textBoxWidth = min(
                    0.95,
                    max(0.15, widthStart + value.translation.width / canvasSize.width)
                )
            }
            .onEnded
            { _ in
                widthStart = nil
            }
    }

    /// Applies the resize drag interaction without retaining image content.
    private func resizeGesture(canvasSize: CGSize) -> some Gesture
    {
        DragGesture(minimumDistance: 0)
            .onChanged
            { value in
                if resizeStart == nil
                {
                    resizeStart = (settings.textBoxWidth, settings.textSize)
                }
                guard let resizeStart
                else
                {
                    return
                }
                let widthChange = value.translation.width / canvasSize.width
                let sizeChange = value.translation.height / min(canvasSize.width, canvasSize.height)
                settings.textBoxWidth = min(0.95, max(0.15, resizeStart.width + widthChange))
                settings.textSize = min(0.25, max(0.025, resizeStart.size + sizeChange))
            }
            .onEnded
            { _ in
                resizeStart = nil
            }
    }

    /// Applies the rotation drag interaction without retaining image content.
    private func rotationGesture(canvasSize: CGSize) -> some Gesture
    {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("decorationCanvas"))
            .onChanged
            { value in
                let center = CGPoint(
                    x: canvasSize.width * settings.textX,
                    y: canvasSize.height * settings.textY
                )
                let deltaX = value.location.x - center.x
                let deltaY = value.location.y - center.y
                settings.textRotation = atan2(deltaY, deltaX) * 180 / .pi + 90
            }
    }

    /// Resolves text appearance before adding selection handles and image-relative placement.
    private func styledText(fontSize: CGFloat, boxWidth: CGFloat) -> some View
    {
        Text(settings.text)
            .font(.custom(settings.fontName, size: fontSize))
            .foregroundStyle(settings.resolvedTextColor.opacity(settings.textOpacity))
            .multilineTextAlignment(.center)
            .frame(width: boxWidth)
            .padding(fontSize * 0.2)
            .background
            {
                if settings.textStyle == .badge
                {
                    RoundedRectangle(cornerRadius: fontSize * 0.18)
                        .fill(.black.opacity(0.58 * settings.textOpacity))
                }
            }
            .shadow(
                color: settings.textStyle == .shadow ? .black.opacity(0.8 * settings.textOpacity) : .clear,
                radius: fontSize * 0.08,
                x: fontSize * 0.04,
                y: fontSize * 0.04
            )
    }

    /// Adds the selection border and independent drag handles before image-relative transforms.
    private func textControls<Content: View>(_ content: Content, canvasSize: CGSize) -> some View
    {
        content
            .overlay
            {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.white, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .shadow(color: .black.opacity(0.8), radius: 1)
            }
            .overlay(alignment: .trailing)
            {
                widthHandle(canvasSize: canvasSize)
                    .offset(x: 12)
            }
            .overlay(alignment: .bottomTrailing)
            {
                resizeHandle(canvasSize: canvasSize)
                    .offset(x: 12, y: 12)
            }
            .overlay(alignment: .top)
            {
                rotationHandle(canvasSize: canvasSize)
                    .offset(y: -38)
            }
    }
}
