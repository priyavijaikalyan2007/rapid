// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 0f5f29a6-9c4f-4780-b575-73cd8207dc60
// Created: 2026
// COMPONENT: ResourceLibraryView
// PURPOSE: Composes the native ResourceLibraryView user interface.
// RELATES: [[CropPrint]]
// FLOW: Native application -> ResourceLibraryView -> local result.

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Composes the native ResourceLibraryView user interface.
struct ResourceLibraryView: View
{
    /// Library used by ResourceLibraryView.
    @EnvironmentObject private var library: ResourceLibrary

    /// Native scene or view content derived from the current application state.
    var body: some View
    {
        NavigationStack
        {
            Form
            {
                Section("Remote catalog")
                {
                    TextField("HTTPS catalog address", text: $library.catalogURLString)
                        .textContentType(.URL)

                    Button("Refresh Catalog")
                    {
                        Task
                        {
                            await library.refreshCatalog()
                        }
                    }

                    Text("Leave the address empty to use the built-in Google Fonts catalog.")
                        .font(.caption)
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
                                resourceRow(resource)
                            }
                        }
                    }
                }

                Section("Status")
                {
                    Text(library.status)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Remote Resources")
        }
        .modifier(InformationPlatformFrame(minWidth: 560, minHeight: 480))
    }

    /// Shows the resource license and an explicit download action.
    private func resourceRow(_ resource: RemoteResource) -> some View
    {
        HStack
        {
            VStack(alignment: .leading, spacing: 3)
            {
                Text(resource.name)
                    .font(.headline)
                Text("\(resource.creator) · \(resource.licenseName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if library.isDownloaded(resource)
            {
                Label("Downloaded", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            else
            {
                downloadButton(resource: resource)
                    .disabled(library.activeDownloads.contains(resource.id))
            }
        }
    }

    /// Builds the download button using the same local state.
    @ViewBuilder
    private func downloadButton(resource: RemoteResource) -> some View
    {
        Button("Download")
        {
            Task
            {
                await library.download(resource)
            }
        }
    }
}
