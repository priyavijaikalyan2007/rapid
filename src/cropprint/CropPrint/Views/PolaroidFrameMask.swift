// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c2b41af7-eb96-4554-945b-805c0e716e62
// Created: 2026
// COMPONENT: PolaroidFrameMask
// PURPOSE: Composes the native PolaroidFrameMask user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PolaroidFrameMask -> local result.

import SwiftUI

/// Composes the native PolaroidFrameMask user interface.
struct PolaroidFrameMask: View
{
    /// The width value supplied to this PolaroidFrameMask instance.
    let width: CGFloat

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        VStack(spacing: 0)
        {
            Rectangle().frame(height: width)
            HStack(spacing: 0)
            {
                Rectangle().frame(width: width)
                Color.clear
                Rectangle().frame(width: width)
            }
            Rectangle().frame(height: width * 2.6)
        }
    }
}
