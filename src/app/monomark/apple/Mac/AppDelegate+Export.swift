// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 82954dc5-d018-4603-8ebc-7de7c075cefa
// COMPONENT: Native explicit annotation export
// PURPOSE: Distinguish local autosave from writes to a Markdown file.
// FLOW: File menu action -> local flush -> scoped export -> reader refresh.

import AppKit
import UniformTypeIdentifiers

extension AppDelegate
{
    @objc func exportReadingData(_ sender: Any?)
    {
        guard let session = current?.session, let source = session.url, session.annotations.ready
        else
        {
            return
        }
        Task
        {
            guard await session.annotations.drain()
            else
            {
                return
            }
            do
            {
                try await writeReadingData(session, source: source, destination: source)
            }
            catch
            {
                let failure = error as NSError
                if (failure.domain == NSCocoaErrorDomain && failure.code == CocoaError.fileWriteNoPermission
                    .rawValue) ||
                    (failure.domain == NSPOSIXErrorDomain && [1, 13].contains(failure.code))
                {
                    chooseExport(session, source: source, sameFile: true)
                }
                else
                {
                    NSAlert(error: error).runModal()
                }
            }
        }
    }

    @objc func exportReadingCopy(_ sender: Any?)
    {
        guard let session = current?.session, let source = session.url, session.annotations.ready
        else
        {
            return
        }
        Task
        {
            guard await session.annotations.drain()
            else
            {
                return
            }
            chooseExport(session, source: source, sameFile: false)
        }
    }

    private func chooseExport(_ session: ReaderSession, source: URL, sameFile: Bool)
    {
        let panel = NSSavePanel()
        panel.title = sameFile ? "Allow Export to This Markdown File" : "Export a Copy"
        panel.prompt = "Export"
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        panel.directoryURL = source.deletingLastPathComponent()
        panel.nameFieldStringValue = sameFile ? source.lastPathComponent :
            source.deletingPathExtension().lastPathComponent + "-reading-notes.md"
        guard panel.runModal() == .OK, let destination = panel.url
        else
        {
            return
        }
        if sameFile && destination.standardizedFileURL != source.standardizedFileURL
        {
            session.message = "Choose the current file for this action, or use Export a Copy."
            return
        }
        Task
        {
            do
            {
                try await writeReadingData(session, source: source, destination: destination)
            }
            catch
            {
                NSAlert(error: error).runModal()
            }
        }
    }

    private func writeReadingData(_ session: ReaderSession, source: URL, destination: URL) async throws
    {
        let notes = ReadingNotes(
            annotations: session.annotations.records,
            text: session.annotations.text,
            format: session.annotations.format
        )
        let accessing = destination.startAccessingSecurityScopedResource()
        defer
        {
            if accessing
            {
                destination.stopAccessingSecurityScopedResource()
            }
        }
        try await Task.detached(priority: .userInitiated)
        {
            try AnnotationExportWriter.write(source: source, destination: destination, notes: notes)
        }.value
        session.message = "Exported notes and annotations to \(destination.lastPathComponent)."
        if source.standardizedFileURL == destination.standardizedFileURL, session.url == source
        {
            session.open(source, folder: session.root == source ? nil : session.root, resume: session.state)
        }
    }
}
