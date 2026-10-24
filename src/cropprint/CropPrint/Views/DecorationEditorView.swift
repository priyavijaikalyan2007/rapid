// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 09950730-9c0a-4fc1-9973-919f9a34315e
// Created: 2026
// COMPONENT: DecorationEditorView
// PURPOSE: Composes the native DecorationEditorView user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> DecorationEditorView -> local result.

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Composes the native DecorationEditorView user interface.
struct DecorationEditorView: View
{
    /// Dismiss used by DecorationEditorView.
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: ResourceLibrary
    @Binding var settings: DecorationSettings
    var showsDoneButton = true

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        NavigationStack
        {
            decorationForm
                .formStyle(.grouped)
                .navigationTitle("Decorate")
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
        .modifier(DecorationEditorPlatformFrame(showsDoneButton: showsDoneButton))
    }

    /// Custom text color component from zero through one.
    private var customTextColor: Binding<Color>
    {
        Binding
        {
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

    /// Custom frame color component from zero through one.
    private var customFrameColor: Binding<Color>
    {
        Binding
        {
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

    /// Builds the font picker using the same local state.
    @ViewBuilder
    private var fontPicker: some View
    {
        Picker("Font", selection: $settings.fontName)
        {
            Text("Helvetica Neue Bold").tag("HelveticaNeue-Bold")
            Text("Avenir Next Bold").tag("AvenirNext-Bold")
            Text("Georgia Bold").tag("Georgia-Bold")
            ForEach(library.availableFonts, id: \.fontName)
            { font in
                Text(font.name).tag(font.fontName)
            }
        }
    }

    /// Builds the text style picker using the same local state.
    @ViewBuilder
    private var textStylePicker: some View
    {
        Picker("Style", selection: $settings.textStyle)
        {
            ForEach(TextDecorationStyle.allCases)
            { style in
                Text(style.rawValue).tag(style)
            }
        }
    }

    /// Builds the frame style picker using the same local state.
    @ViewBuilder
    private var frameStylePicker: some View
    {
        Picker("Style", selection: $settings.frameStyle)
        {
            ForEach(PhotoFrameStyle.allCases)
            { style in
                Text(style.rawValue).tag(style)
            }
        }
    }

    /// Builds the text color palette using the same local state.
    @ViewBuilder
    private var textColorPalette: some View
    {
        LabeledContent("Color")
        {
            HStack(spacing: 8)
            {
                ForEach(DecorationColor.allCases)
                { color in
                    Button
                    {
                        settings.textColor = color
                        settings.usesCustomTextColor = false
                    } label: {
                        Circle()
                            .fill(color.color)
                            .frame(width: 22, height: 22)
                            .overlay
                            {
                                Circle().stroke(
                                    settings.textColor == color && !settings.usesCustomTextColor
                                        ? Color.accentColor
                                        : Color.secondary.opacity(0.45),
                                    lineWidth: settings.textColor == color && !settings
                                        .usesCustomTextColor ? 3 : 1
                                )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(color.title)
                }
            }
        }
    }

    /// Builds the frame color palette using the same local state.
    @ViewBuilder
    private var frameColorPalette: some View
    {
        LabeledContent("Color")
        {
            HStack(spacing: 8)
            {
                ForEach(DecorationColor.allCases)
                { color in
                    Button
                    {
                        settings.frameColor = color
                        settings.usesCustomFrameColor = false
                    } label: {
                        Circle()
                            .fill(color.color)
                            .frame(width: 22, height: 22)
                            .overlay
                            {
                                Circle().stroke(
                                    settings.frameColor == color && !settings.usesCustomFrameColor
                                        ? Color.accentColor
                                        : Color.secondary.opacity(0.45),
                                    lineWidth: settings.frameColor == color && !settings
                                        .usesCustomFrameColor ? 3 : 1
                                )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(color.title)
                }
            }
        }
    }

    /// Builds the text section using the same local state.
    @ViewBuilder
    private var textSection: some View
    {
        Section("Text")
        {
            Text(
                """
                Drag the text box to move it. Use the side circle to change its width. Use the corner \
                square to scale it. Use the blue handle to rotate it.
                """
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            TextField("Text", text: $settings.text, axis: .vertical)
                .lineLimit(1 ... 3)

            fontPicker

            textStylePicker

            textColorPalette

            ColorPicker(
                "Custom color",
                selection: customTextColor,
                supportsOpacity: false
            )

            LabeledContent("Size", value: "\(Int(settings.textSize * 100))%")
            Slider(value: $settings.textSize, in: 0.025 ... 0.25)

            LabeledContent("Opacity", value: "\(Int(settings.textOpacity * 100))%")
            Slider(value: $settings.textOpacity, in: 0.1 ... 1)

            LabeledContent("Rotation", value: "\(Int(settings.textRotation))°")
            Slider(value: $settings.textRotation, in: -180 ... 180, step: 1)

            LabeledContent("Horizontal position", value: "\(Int(settings.textX * 100))%")
            Slider(value: $settings.textX, in: 0.05 ... 0.95)

            LabeledContent("Vertical position", value: "\(Int(settings.textY * 100))%")
            Slider(value: $settings.textY, in: 0.05 ... 0.95)
        }
    }

    /// Builds the frame section using the same local state.
    @ViewBuilder
    private var frameSection: some View
    {
        Section("Frame")
        {
            frameStylePicker

            frameColorPalette

            ColorPicker(
                "Custom color",
                selection: customFrameColor,
                supportsOpacity: false
            )

            LabeledContent("Width", value: "\(Int(settings.frameWidth * 100))%")
            Slider(value: $settings.frameWidth, in: 0.005 ... 0.12)

            LabeledContent("Opacity", value: "\(Int(settings.frameOpacity * 100))%")
            Slider(value: $settings.frameOpacity, in: 0.1 ... 1)

            Picker("Downloaded frame", selection: $settings.remoteFrameID)
            {
                Text("None").tag(nil as String?)
                ForEach(library.availableFrames)
                { frame in
                    Text(frame.name).tag(frame.id as String?)
                }
            }

            if library.availableFrames.isEmpty
            {
                Text("Download a frame from Remote Resources to add it here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Builds the decoration form using the same local state.
    @ViewBuilder
    private var decorationForm: some View
    {
        Form
        {
            textSection

            frameSection

            Section
            {
                Button("Remove All Decorations", role: .destructive)
                {
                    settings = DecorationSettings()
                }
            }
        }
    }
}
