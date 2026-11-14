// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 7e3ad8c4-7b9e-4602-9671-07fbf7bdca59
// COMPONENT: Local document change observation
// PURPOSE: Release file observation when a document closes or changes.
// FLOW: Filesystem event -> current generation check -> reader refresh.

import Foundation

extension ReaderSession
{
    func watch(_ file: URL)
    {
        watcher?.cancel()
        let descriptor = Darwin.open(file.path, O_EVTONLY)
        guard descriptor >= 0
        else
        {
            return
        }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )
        let ticket = documentEpoch
        source.setEventHandler
        { [weak self] in
            Task
            { @MainActor in
                guard let self, self.documentEpoch == ticket
                else
                {
                    return
                }
                self.message = "The file changed outside MonoMark. Reload to view the latest content."
                if self.watcher?.data.contains(.write) == true
                {
                    self.loadRenderer()
                }
            }
        }
        source.setCancelHandler
        {
            Darwin.close(descriptor)
        }
        watcher = source
        source.resume()
    }
}
