// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4fcea122-682a-4d5a-80fe-466e5d5d0b5f
// Created: 2026
// COMPONENT: InformationCommands
// PURPOSE: Defines the InformationCommands domain values and their contracts.
// RELATES: [[CropPrint]]
// FLOW: Native application -> InformationCommands -> local result.

import SwiftUI

/// Defines the InformationCommands domain values and their contracts.
struct InformationCommands: Commands
{
    /// Open window used by InformationCommands.
    @Environment(\.openWindow) private var openWindow

    /// Native scene or view content derived from the current application state.
    var body: some Commands
    {
        CommandGroup(replacing: .appInfo)
        {
            Button("About CropPrint")
            {
                openWindow(id: "about-cropprint")
            }

            Button("Attributions…")
            {
                openWindow(id: "attributions")
            }

            Button("Remote Resources…")
            {
                openWindow(id: "remote-resources")
            }
        }

        CommandGroup(replacing: .help)
        {
            Button("CropPrint Help")
            {
                openWindow(id: "cropprint-help")
            }
            .keyboardShortcut("?", modifiers: .command)

            Link(destination: URL(string: "https://github.com/priyavijaikalyan2007/rapid/issues/new/choose")!)
            {
                Text("Report an Issue…")
            }
        }
    }
}
