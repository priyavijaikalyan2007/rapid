// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 208f7805-5fc1-4348-b4e5-dc25a9da8876
// Created: 2026
// COMPONENT: DecorationOverlay
// PURPOSE: Composes the native DecorationOverlay user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> DecorationOverlay -> local result.

import SwiftUI

/// Composes the native DecorationOverlay user interface.
struct DecorationOverlay: View
{
    /// Current settings shared by the editor, preview, and export.
    let settings: DecorationSettings
    /// The remote frame value supplied to this DecorationOverlay instance.
    let remoteFrame: Image?

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        GeometryReader
        { proxy in
            let size = proxy.size
            ZStack
            {
                frame(in: size)
                text(in: size)
            }
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Builds the built-in or downloaded frame overlay for the current canvas.
    @ViewBuilder
    private func frame(in size: CGSize) -> some View
    {
        let width = max(1, min(size.width, size.height) * settings.frameWidth)
        let color = settings.resolvedFrameColor.opacity(settings.frameOpacity)

        builtInFrame(width: width, color: color)

        if let remoteFrame
        {
            remoteFrame
                .resizable()
                .frame(width: size.width, height: size.height)
                .opacity(settings.frameOpacity)
        }
    }

    /// Builds the styled text overlay at its normalized image position.
    @ViewBuilder
    private func text(in size: CGSize) -> some View
    {
        if settings.hasText
        {
            let fontSize = max(8, min(size.width, size.height) * settings.textSize)
            styledText(in: size, fontSize: fontSize)
                .shadow(
                    color: settings.textStyle == .shadow ? .black.opacity(0.8 * settings.textOpacity) : .clear,
                    radius: fontSize * 0.08,
                    x: fontSize * 0.04,
                    y: fontSize * 0.04
                )
                .overlay
                {
                    outlineText(fontSize: fontSize)
                }
                .rotationEffect(.degrees(settings.textRotation))
                .position(x: size.width * settings.textX, y: size.height * settings.textY)
        }
    }

    /// Builds the built in frame using the same local state.
    @ViewBuilder
    private func builtInFrame(width: CGFloat, color: Color) -> some View
    {
        switch settings.frameStyle
        {
        case .none:
            EmptyView()
        case .classic:
            Rectangle().strokeBorder(color, lineWidth: width)
        case .double:
            ZStack
            {
                Rectangle().strokeBorder(color, lineWidth: width)
                Rectangle().inset(by: width * 1.8).strokeBorder(color, lineWidth: max(1, width * 0.35))
            }
        case .rounded:
            RoundedRectangle(cornerRadius: width * 2.2).strokeBorder(color, lineWidth: width)
        case .film:
            Rectangle().strokeBorder(.black.opacity(settings.frameOpacity), lineWidth: width * 2.2)
        case .polaroid:
            PolaroidFrameShape(bottomScale: 2.6)
                .fill(color)
                .padding(0)
                .mask(PolaroidFrameMask(width: width))
        }
    }

    /// Builds the outline text using the same local state.
    @ViewBuilder
    private func outlineText(fontSize: CGFloat) -> some View
    {
        if settings.textStyle == .outline
        {
            Text(settings.text)
                .font(.custom(settings.fontName, size: fontSize))
                .foregroundStyle(.clear)
                .shadow(color: .black.opacity(settings.textOpacity), radius: 1)
        }
    }

    /// Applies font, color, wrapping, and the optional badge before position transforms.
    private func styledText(in size: CGSize, fontSize: CGFloat) -> some View
    {
        Text(settings.text)
            .font(.custom(settings.fontName, size: fontSize))
            .foregroundStyle(settings.resolvedTextColor.opacity(settings.textOpacity))
            .multilineTextAlignment(.center)
            .frame(width: size.width * settings.textBoxWidth)
            .padding(settings.textStyle == .badge ? fontSize * 0.22 : 0)
            .background
            {
                if settings.textStyle == .badge
                {
                    RoundedRectangle(cornerRadius: fontSize * 0.18)
                        .fill(.black.opacity(0.58 * settings.textOpacity))
                }
            }
    }
}
