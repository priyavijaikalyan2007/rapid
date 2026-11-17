// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: cb532225-2d64-419e-a652-c42223416180
// COMPONENT: Explicit reading-data export
// PURPOSE: Coordinate a fresh source read and an atomic Markdown export.
// FLOW: User export command -> coordinated source -> generated section -> atomic destination.

import Foundation

/// Source replacement is available only through a native explicit export action.
enum AnnotationExportWriter
{
    static func write(
        source: URL,
        destination: URL,
        notes: ReadingNotes,
        options: ReadingExportOptions = ReadingExportOptions()
    ) throws
    {
        let sameFile = sameFile(source, destination)
        guard !options.dataOnly || !sameFile
        else
        {
            throw ReaderFailure.denied
        }
        if options.dataOnly, options.selected(notes).annotations.isEmpty
        {
            try writeNotesOnly(destination: destination, notes: notes, options: options)
            return
        }
        var coordinationError: NSError?
        var result: Result<Void, Error> = .failure(ReaderFailure.unavailable)
        let coordinator = NSFileCoordinator()
        if sameFile
        {
            coordinator.coordinate(writingItemAt: source, options: .forReplacing, error: &coordinationError)
            { file in
                result = Result
                {
                    try replace(source: file, destination: file, notes: notes, options: options)
                }
            }
        }
        else
        {
            coordinator.coordinate(
                readingItemAt: source,
                options: .withoutChanges,
                writingItemAt: destination,
                options: .forReplacing,
                error: &coordinationError
            )
            { input, output in
                result = Result
                {
                    try replace(source: input, destination: output, notes: notes, options: options)
                }
            }
        }
        if let coordinationError
        {
            throw coordinationError
        }
        try result.get()
    }

    private static func sameFile(_ source: URL, _ destination: URL) -> Bool
    {
        let source = source.resolvingSymlinksInPath().standardizedFileURL
        let destination = destination.resolvingSymlinksInPath().standardizedFileURL
        if source == destination
        {
            return true
        }
        guard let sourceID = try? DocumentAccess.identity(source),
              let destinationID = try? DocumentAccess.identity(destination)
        else
        {
            return false
        }
        return sourceID == destinationID
    }

    private static func replace(
        source: URL,
        destination: URL,
        notes: ReadingNotes,
        options: ReadingExportOptions
    ) throws
    {
        let bytes = try DocumentAccess.boundedRead(source, limit: DocumentAccess.sourceLimit)
        let current = String(decoding: bytes, as: UTF8.self)
        if let expected = notes.sourceHash, expected != DocumentStamp.make(current)
        {
            throw AnnotationFailure.sourceChanged
        }
        let output = try options.render(source: current, notes: notes)
        try Data(output.utf8).write(to: destination, options: .atomic)
    }

    /// Standalone local notes do not require a source file that may have moved or disappeared.
    private static func writeNotesOnly(destination: URL, notes: ReadingNotes, options: ReadingExportOptions) throws
    {
        let output = try options.render(source: "", notes: notes)
        var coordinationError: NSError?
        var failure: Error?
        NSFileCoordinator().coordinate(writingItemAt: destination, options: .forReplacing, error: &coordinationError)
        { file in
            do
            {
                try Data(output.utf8).write(to: file, options: .atomic)
            }
            catch
            {
                failure = error
            }
        }
        if let failure
        {
            throw failure
        }
        if let coordinationError
        {
            throw coordinationError
        }
    }
}
