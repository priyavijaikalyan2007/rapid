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
    @objc func showExportOptions(_ sender: Any?)
    {
        guard current?.session.annotations.ready == true
        else
        {
            return
        }
        current?.session.showExportOptions = true
    }

    func performReadingExport(
        _ session: ReaderSession,
        options: ReadingExportOptions,
        destination: ReadingExportDestination
    )
    {
        guard let source = session.url
        else
        {
            return
        }
        if destination != .currentFile
        {
            chooseExport(session, source: source, sameFile: false, options: options)
            return
        }
        Task
        {
            do
            {
                try await writeReadingData(session, source: source, destination: source, options: options)
            }
            catch
            {
                if requiresWriteGrant(error)
                {
                    chooseExport(session, source: source, sameFile: true, options: options)
                }
                else
                {
                    NSAlert(error: error).runModal()
                }
            }
        }
    }

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
                if requiresWriteGrant(error)
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

    private func chooseExport(
        _ session: ReaderSession,
        source: URL,
        sameFile: Bool,
        options: ReadingExportOptions = ReadingExportOptions()
    )
    {
        let panel = NSSavePanel()
        panel.title = sameFile ? "Allow Export to This Markdown File" : options.dataOnly ? "Export Reading Data" : "Export a Copy"
        panel.prompt = "Export"
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        panel.directoryURL = source.deletingLastPathComponent()
        panel.nameFieldStringValue = sameFile ? source.lastPathComponent :
            source.deletingPathExtension()
            .lastPathComponent + (options.dataOnly ? "-reading-data.md" : "-reading-notes.md")
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
        if options.dataOnly, destination.resolvingSymlinksInPath() == source.resolvingSymlinksInPath()
        {
            session.message = "Choose a separate filename for reading data. The source document is unchanged."
            return
        }
        Task
        {
            do
            {
                try await writeReadingData(session, source: source, destination: destination, options: options)
            }
            catch
            {
                NSAlert(error: error).runModal()
            }
        }
    }

    private func writeReadingData(
        _ session: ReaderSession,
        source: URL,
        destination: URL,
        options: ReadingExportOptions = ReadingExportOptions()
    ) async throws
    {
        let needsSource = !options.dataOnly || (options.includeAnnotations && !session.annotations.records.isEmpty)
        let notes = try await session.readingNotesForExport(
            includeAnnotations: options.includeAnnotations,
            requireSource: needsSource
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
            try AnnotationExportWriter.write(source: source, destination: destination, notes: notes, options: options)
        }.value
        session.message = "Exported reading data to \(destination.lastPathComponent)."
        if source.standardizedFileURL == destination.standardizedFileURL, session.url == source
        {
            session.open(source, folder: session.root == source ? nil : session.root, resume: session.state)
        }
    }

    private func requiresWriteGrant(_ error: Error) -> Bool
    {
        let failure = error as NSError
        return (failure.domain == NSCocoaErrorDomain && failure.code == CocoaError.fileWriteNoPermission.rawValue) ||
            (failure.domain == NSPOSIXErrorDomain && [1, 13].contains(failure.code))
    }
}
