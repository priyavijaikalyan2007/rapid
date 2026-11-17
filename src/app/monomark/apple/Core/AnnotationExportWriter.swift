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
    static func write(source: URL, destination: URL, notes: ReadingNotes) throws
    {
        var coordinationError: NSError?
        var result: Result<Void, Error> = .failure(ReaderFailure.unavailable)
        let coordinator = NSFileCoordinator()
        if source.standardizedFileURL == destination.standardizedFileURL
        {
            coordinator.coordinate(writingItemAt: source, options: .forReplacing, error: &coordinationError)
            { file in
                result = Result
                {
                    try replace(source: file, destination: file, notes: notes)
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
                    try replace(source: input, destination: output, notes: notes)
                }
            }
        }
        if let coordinationError
        {
            throw coordinationError
        }
        try result.get()
    }

    private static func replace(source: URL, destination: URL, notes: ReadingNotes) throws
    {
        let bytes = try DocumentAccess.boundedRead(source, limit: DocumentAccess.sourceLimit)
        let current = String(decoding: bytes, as: UTF8.self)
        if let expected = notes.sourceHash, expected != DocumentStamp.make(current)
        {
            throw AnnotationFailure.sourceChanged
        }
        let output = try AnnotationExporter.render(source: current, notes: notes)
        try Data(output.utf8).write(to: destination, options: .atomic)
    }
}
