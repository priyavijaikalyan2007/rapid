// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b295fdaa-e5c7-4802-b46e-2904e3214a7d
// Created: 2026
// COMPONENT: DecorationSettings
// PURPOSE: Stores normalized text and frame choices shared by preview and export.
// RELATES: [[CropPrint]]
// FLOW: Native application -> DecorationSettings -> local result.

import SwiftUI

/// Stores normalized text and frame choices shared by preview and export.
struct DecorationSettings
{
    /// Text used by DecorationSettings.
    var text = ""
    /// PostScript font name used only by local platform font rendering.
    var fontName = "HelveticaNeue-Bold"
    /// Text font size as a fraction of the smaller image dimension.
    var textSize: CGFloat = 0.08
    /// Text color used by DecorationSettings.
    var textColor = DecorationColor.white
    /// Custom text red component from zero through one.
    var customTextRed = 1.0
    /// Custom text green component from zero through one.
    var customTextGreen = 1.0
    /// Custom text blue component from zero through one.
    var customTextBlue = 1.0
    /// Selects a custom text color instead of the named palette color.
    var usesCustomTextColor = false
    /// Text opacity from zero through one.
    var textOpacity = 1.0
    /// Text rotation in degrees around the text center.
    var textRotation = 0.0
    /// Horizontal text center as a fraction of the image width.
    var textX: CGFloat = 0.5
    /// Vertical text center as a fraction of the image height from the top.
    var textY: CGFloat = 0.82
    /// Maximum text width as a fraction of the image width.
    var textBoxWidth: CGFloat = 0.72
    /// Text style used by DecorationSettings.
    var textStyle = TextDecorationStyle.shadow

    /// Frame style used by DecorationSettings.
    var frameStyle = PhotoFrameStyle.none
    /// Frame color used by DecorationSettings.
    var frameColor = DecorationColor.white
    /// Custom frame red component from zero through one.
    var customFrameRed = 1.0
    /// Custom frame green component from zero through one.
    var customFrameGreen = 1.0
    /// Custom frame blue component from zero through one.
    var customFrameBlue = 1.0
    /// Selects a custom frame color instead of the named palette color.
    var usesCustomFrameColor = false
    /// Frame thickness as a fraction of the smaller image dimension.
    var frameWidth: CGFloat = 0.025
    /// Frame opacity from zero through one.
    var frameOpacity = 1.0
    /// Optional catalog identifier for a locally cached licensed frame.
    var remoteFrameID: String?

    /// Has text used by DecorationSettings.
    var hasText: Bool
    {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Has frame used by DecorationSettings.
    var hasFrame: Bool
    {
        frameStyle != .none || remoteFrameID != nil
    }

    /// Has decorations used by DecorationSettings.
    var hasDecorations: Bool
    {
        hasText || hasFrame
    }

    /// Resolved text color used by DecorationSettings.
    var resolvedTextColor: Color
    {
        usesCustomTextColor
            ? Color(red: customTextRed, green: customTextGreen, blue: customTextBlue)
            : textColor.color
    }

    /// Resolved text cgcolor used by DecorationSettings.
    var resolvedTextCGColor: CGColor
    {
        usesCustomTextColor
            ? CGColor(srgbRed: customTextRed, green: customTextGreen, blue: customTextBlue, alpha: 1)
            : textColor.cgColor
    }

    /// Resolved frame color used by DecorationSettings.
    var resolvedFrameColor: Color
    {
        usesCustomFrameColor
            ? Color(red: customFrameRed, green: customFrameGreen, blue: customFrameBlue)
            : frameColor.color
    }

    /// Resolved frame cgcolor used by DecorationSettings.
    var resolvedFrameCGColor: CGColor
    {
        usesCustomFrameColor
            ? CGColor(srgbRed: customFrameRed, green: customFrameGreen, blue: customFrameBlue, alpha: 1)
            : frameColor.cgColor
    }
}
