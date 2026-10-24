// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c170312e-c18f-4da7-8f6b-ed2e4d7c9c0c
// Created: 2026
// COMPONENT: ReplacementBackground
// PURPOSE: Selects the original background or a supported solid local replacement.
// RELATES: [[CropPrint]]
// FLOW: Native application -> ReplacementBackground -> local result.

import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import Vision

/// Selects the original background or a supported solid local replacement.
enum ReplacementBackground: String, CaseIterable, Identifiable
{
    /// Selects original within this type's supported choices.
    case original = "Keep original"
    /// Selects white within this type's supported choices.
    case white = "White"
    /// Selects light gray within this type's supported choices.
    case lightGray = "Light gray"
    /// Selects light blue within this type's supported choices.
    case lightBlue = "Light blue"

    /// Identity used by native selection controls.
    var id: Self
    {
        self
    }

    /// Color used by ReplacementBackground.
    var color: CIColor?
    {
        switch self
        {
        case .original: nil
        case .white: CIColor(red: 1, green: 1, blue: 1)
        case .lightGray: CIColor(red: 0.9, green: 0.9, blue: 0.9)
        case .lightBlue: CIColor(red: 0.78, green: 0.88, blue: 0.98)
        }
    }
}
