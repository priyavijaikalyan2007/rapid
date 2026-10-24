// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 307f05f8-c6e2-4aa5-9bc6-2fb4dc6c5e97
// Created: 2026
// COMPONENT: AboutCropPrintView
// PURPOSE: Composes the native AboutCropPrintView user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> AboutCropPrintView -> local result.

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Composes the native AboutCropPrintView user interface.
struct AboutCropPrintView: View
{
    /// Version used by AboutCropPrintView.
    private var version: String
    {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    /// Build number used by AboutCropPrintView.
    private var buildNumber: String
    {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    /// Git sha used by AboutCropPrintView.
    private var gitSHA: String
    {
        let value = Bundle.main.object(forInfoDictionaryKey: "CropPrintGitSHA") as? String
        guard let value, !value.isEmpty, !value.contains("$(")
        else
        {
            return "development"
        }
        return value
    }

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        VStack(alignment: .leading, spacing: 16)
        {
            HStack(spacing: 16)
            {
                Image("BrandIcon")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)

                Text("CropPrint")
                    .font(.largeTitle.bold())
            }

            Text("Version \(version)+\(gitSHA) (build \(buildNumber))")
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Text(
                """
                CropPrint crops photos to exact print, social-media, phone, and display ratios. It never changes \
                the original photo.
                """
            )

            Text("Privacy")
                .font(.headline)

            Text(
                """
                CropPrint has no login, analytics, advertising, or data collection. It contacts a server only when \
                you refresh or download remote resources. The server receives normal request data, such as your \
                Internet Protocol address.
                """
            )

            Text("CropPrint uses GNU GPL version 3 or later. Remote fonts and frames keep their own licenses.")

            Link("View the Privacy Policy", destination: URL(string: "https://outcrop.us/privacy/")!)

            Link(
                "Report an Issue",
                destination: URL(string: "https://github.com/priyavijaikalyan2007/rapid/issues/new/choose")!
            )

            Link("View the GNU GPL", destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!)

            Spacer()
        }
        .padding(24)
        .modifier(InformationPlatformFrame(minWidth: 420, minHeight: 360))
    }
}
