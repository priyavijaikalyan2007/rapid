// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4f727096-f38d-4c20-a749-ec2be5ac7ff2
// Created: 2026
// COMPONENT: RuleOfThirdsGrid
// PURPOSE: Defines the drawing path for RuleOfThirdsGrid.
// RELATES: [[CropPrint]]
// FLOW: Native application -> RuleOfThirdsGrid -> local result.

import SwiftUI

/// Defines the drawing path for RuleOfThirdsGrid.
struct RuleOfThirdsGrid: Shape
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
