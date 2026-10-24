// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 8a051bcd-5951-4fe3-874c-29af0d0c69bd
// Created: 2026
// COMPONENT: View
// PURPOSE: Adds CropCanvas behavior to View.
// RELATES: [[CropPrint]]
// FLOW: Native application -> View -> local result.

import SwiftUI

/// Adds CropCanvas behavior to View.
extension View
{
    /// Shows the requested native pointer only while the crop control is hovered.
    @ViewBuilder
    func cursor(_ cursor: NSCursor) -> some View
    {
        onHover
        { isInside in
            if isInside
            {
                cursor.push()
            }
            else
            {
                NSCursor.pop()
            }
        }
    }
}
