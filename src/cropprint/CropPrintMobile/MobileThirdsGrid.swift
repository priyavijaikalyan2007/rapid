// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 76803837-d2d6-458f-b990-3bba186fe49c
// Created: 2026
// COMPONENT: MobileThirdsGrid
// PURPOSE: Defines the drawing path for MobileThirdsGrid.
// RELATES: [[CropPrint]]
// FLOW: Native application -> MobileThirdsGrid -> local result.

import SwiftUI

/// Defines the drawing path for MobileThirdsGrid.
struct MobileThirdsGrid: Shape
{
    /// Constructs the shape within the supplied drawing rectangle.
    func path(in rect: CGRect) -> Path
    {
        var path = Path()
        for fraction in [CGFloat(1) / 3, CGFloat(2) / 3]
        {
            path.move(to: CGPoint(x: rect.width * fraction, y: 0))
            path.addLine(to: CGPoint(x: rect.width * fraction, y: rect.height))
            path.move(to: CGPoint(x: 0, y: rect.height * fraction))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height * fraction))
        }
        return path
    }
}
