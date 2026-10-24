// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 1495e627-e96c-4dbd-a9b4-8a3e9fa1041f
// Created: 2026
// COMPONENT: CropPrintApp
// PURPOSE: Composes macOS windows, commands, and shared application state.
// RELATES: [[CropPrint]]
// FLOW: Native application -> CropPrintApp -> local result.

import SwiftUI

/// Composes macOS windows, commands, and shared application state.
@main
struct CropPrintApp: App
{
    /// Document used by CropPrintApp.
    @StateObject private var document = PhotoDocument()
    @StateObject private var resourceLibrary = ResourceLibrary.shared

    /// Native scene or view content derived from the current application state.
    var body: some Scene
    {
        mainWindow
            .commands
            {
                InformationCommands()

                openCommands

                exportCommands
            }

        Window("About CropPrint", id: "about-cropprint")
        {
            AboutCropPrintView()
                .environmentObject(resourceLibrary)
        }

        Window("Attributions", id: "attributions")
        {
            AttributionsView()
                .environmentObject(resourceLibrary)
        }

        Window("Remote Resources", id: "remote-resources")
        {
            ResourceLibraryView()
                .environmentObject(resourceLibrary)
        }

        Window("CropPrint Help", id: "cropprint-help")
        {
            CropPrintHelpView()
        }
    }

    /// Builds the recent photos menu using the same local state.
    @ViewBuilder
    private var recentPhotosMenu: some View
    {
        Menu("Open Recent")
        {
            if document.recentPhotoURLs.isEmpty
            {
                Text("No Recent Photos")
            }
            else
            {
                ForEach(document.recentPhotoURLs, id: \.self)
                { url in
                    Button(url.lastPathComponent)
                    {
                        document.open(url: url)
                    }
                    .help(url.path)
                }

                Divider()

                Button("Clear Menu")
                {
                    document.clearRecentPhotos()
                }
            }
        }
    }

    /// Builds the open commands using the same local state.
    @CommandsBuilder
    private var openCommands: some Commands
    {
        CommandGroup(replacing: .newItem)
        {
            Button("Open Photo…")
            {
                document.showOpenPanel()
            }
            .keyboardShortcut("o")

            recentPhotosMenu
        }
    }

    /// Builds the export commands using the same local state.
    @CommandsBuilder
    private var exportCommands: some Commands
    {
        CommandGroup(after: .saveItem)
        {
            Button("Crop and Save")
            {
                document.cropAndSave()
            }
            .keyboardShortcut("s")
            .disabled(!document.canExport)

            Button("Create Print Sheet…")
            {
                document.showPrintSheetPanel()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(!document.canCreatePrintSheet)
        }
    }

    /// Builds the main window using the same local state.
    @SceneBuilder
    private var mainWindow: some Scene
    {
        WindowGroup
        {
            ContentView()
                .environmentObject(document)
                .environmentObject(resourceLibrary)
                .frame(minWidth: 1180, minHeight: 680)
                .onOpenURL
                { url in
                    document.open(url: url)
                }
        }
    }
}
