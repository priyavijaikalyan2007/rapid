// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: ecae9856-c39b-4ddb-beb2-bf71274d03fa
// Created: 2026
// COMPONENT: PolaroidFrameShape
// PURPOSE: Defines the drawing path for PolaroidFrameShape.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PolaroidFrameShape -> local result.

import SwiftUI

/// Defines the drawing path for PolaroidFrameShape.
struct PolaroidFrameShape: Shape
{
    /// The bottom scale value supplied to this PolaroidFrameShape instance.
    let bottomScale: CGFloat

    /// Constructs the shape within the supplied drawing rectangle.
    func path(in rect: CGRect) -> Path
    {
        Path(rect)
    }
}
