// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 6d0c4897-3632-4714-862d-abd75e2ec6e7
// Created: 2026
// COMPONENT: CropCorner
// PURPOSE: Defines the CropCorner domain values and their contracts.
// RELATES: [[CropPrint]]
// FLOW: Native application -> CropCorner -> local result.

import CoreGraphics

/// Defines the CropCorner domain values and their contracts.
enum CropCorner: CaseIterable
{
    /// Selects top left within this type's supported choices.
    case topLeft
    /// Selects top right within this type's supported choices.
    case topRight
    /// Selects bottom left within this type's supported choices.
    case bottomLeft
    /// Selects bottom right within this type's supported choices.
    case bottomRight

    /// Identifies corners that extend to the right of their fixed anchor.
    var extendsRight: Bool
    {
        self == .topRight || self == .bottomRight
    }

    /// Identifies corners that extend below their fixed anchor in top-origin coordinates.
    var extendsDown: Bool
    {
        self == .bottomLeft || self == .bottomRight
    }

    /// Returns this corner of a rectangle in its current coordinate system.
    func point(in rect: CGRect) -> CGPoint
    {
        CGPoint(x: extendsRight ? rect.maxX : rect.minX, y: extendsDown ? rect.maxY : rect.minY)
    }

    /// Returns the corner that stays fixed while this corner is dragged.
    func anchor(in rect: CGRect) -> CGPoint
    {
        CGPoint(x: extendsRight ? rect.minX : rect.maxX, y: extendsDown ? rect.minY : rect.maxY)
    }

    /// Places a resized rectangle around the unchanged opposite corner.
    func origin(anchor: CGPoint, size: CGSize) -> CGPoint
    {
        CGPoint(x: extendsRight ? anchor.x : anchor.x - size.width, y: extendsDown ? anchor.y : anchor.y - size.height)
    }
}
