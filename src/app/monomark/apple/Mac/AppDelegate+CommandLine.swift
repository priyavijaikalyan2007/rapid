// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 921a70f0-a6bb-4f34-89f1-48990bdb4f58
// COMPONENT: Native command-line installation
// PURPOSE: Install an explicit user-selected symlink to the bundled launcher.
import AppKit

extension AppDelegate
{
    @objc func installCommandLine(_ sender: Any?)
    {
        guard let launcher = Bundle.main.url(forResource: "monoleaf", withExtension: nil, subdirectory: "Renderer")
        else
        {
            return
        }
        let panel = NSSavePanel()
        panel.title = "Install Command Line Tool"
        panel.prompt = "Install"
        panel.message = "Choose a folder on your shell's PATH. Reinstall this link if you move Monoleaf.app."
        panel.nameFieldStringValue = "monoleaf"
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin")
        guard panel.runModal() == .OK, let destination = panel.url
        else
        {
            return
        }
        let accessing = destination.startAccessingSecurityScopedResource()
        defer
        {
            if accessing
            {
                destination.stopAccessingSecurityScopedResource()
            }
        }
        do
        {
            if (try? FileManager.default.destinationOfSymbolicLink(atPath: destination.path)) != launcher.path
            {
                try FileManager.default.createSymbolicLink(at: destination, withDestinationURL: launcher)
            }
            current?.session.message = "Installed \(destination.path). Use monoleaf <folder> or monoleaf <file.md …>."
        }
        catch
        {
            NSAlert(error: error).runModal()
        }
    }
}
