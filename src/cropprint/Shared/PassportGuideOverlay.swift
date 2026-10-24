// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 1d6ed58c-a659-4639-9156-3c43a690221a
// Created: 2026
// COMPONENT: PassportGuideOverlay
// PURPOSE: Composes the native PassportGuideOverlay user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PassportGuideOverlay -> local result.

import Foundation
import SwiftUI

/// Composes the native PassportGuideOverlay user interface.
struct PassportGuideOverlay: View
{
    /// The guide value supplied to this PassportGuideOverlay instance.
    let guide: PassportGuide

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        GeometryReader
        { proxy in
            ZStack(alignment: .topLeading)
            {
                guideBand(
                    title: "Top of head",
                    range: guide.crownBand,
                    size: proxy.size
                )
                guideBand(
                    title: "Chin",
                    range: guide.chinBand,
                    size: proxy.size
                )

                Rectangle()
                    .fill(.yellow.opacity(0.7))
                    .frame(width: 1, height: proxy.size.height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                Text(guide.measurement)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.yellow.opacity(0.85), in: Capsule())
                    .padding(8)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Draws a measured passport guide band within the current crop view.
    private func guideBand(
        title: String,
        range: ClosedRange<CGFloat>,
        size: CGSize
    ) -> some View
    {
        let height = max(2, (range.upperBound - range.lowerBound) * size.height)
        let centerY = (range.lowerBound + range.upperBound) * size.height / 2
        return ZStack(alignment: .trailing)
        {
            Rectangle()
                .fill(.yellow.opacity(0.24))
            Rectangle()
                .stroke(.yellow.opacity(0.95), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.yellow.opacity(0.85), in: Capsule())
                .padding(.trailing, 5)
        }
        .frame(width: size.width, height: height)
        .position(x: size.width / 2, y: centerY)
    }
}
