// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9c5322a6-f682-40b5-9b94-5050b6c3b6c1
// Created: 2026
// COMPONENT: AttributionsView
// PURPOSE: Composes the native AttributionsView user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> AttributionsView -> local result.

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Composes the native AttributionsView user interface.
struct AttributionsView: View
{
    /// Library used by AttributionsView.
    @EnvironmentObject private var library: ResourceLibrary

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        NavigationStack
        {
            List
            {
                Section
                {
                    Text(
                        """
                        Each entry shows its title, creator, source, and exact license. CropPrint rejects \
                        incomplete entries and licenses that prohibit needed changes.
                        """
                    )
                    .foregroundStyle(.secondary)
                }

                ForEach(RemoteResourceKind.allCases, id: \.self)
                { kind in
                    let items = library.resources.filter
                    {
                        $0.kind == kind
                    }
                    if !items.isEmpty
                    {
                        Section(kind.title + "s")
                        {
                            ForEach(items)
                            { resource in
                                attributionRow(resource)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Attributions")
        }
        .modifier(InformationPlatformFrame(minWidth: 560, minHeight: 440))
    }

    /// Displays the resource creator, license, and source without altering license terms.
    private func attributionRow(_ resource: RemoteResource) -> some View
    {
        VStack(alignment: .leading, spacing: 6)
        {
            resourceHeading(resource: resource)
            Text("Creator: \(resource.creator)")
            HStack(spacing: 16)
            {
                Link("Source", destination: resource.sourceURL)
                Link(resource.licenseName, destination: resource.licenseURL)
            }
            .font(.caption)
            if let notes = resource.notes
            {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    /// Builds the resource heading using the same local state.
    @ViewBuilder
    private func resourceHeading(resource: RemoteResource) -> some View
    {
        HStack
        {
            Text(resource.name)
                .font(.headline)
            if library.isDownloaded(resource)
            {
                Label("Downloaded", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
}
