// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: fd7b57b7-093d-4a17-a046-bd57be0d0d71
// COMPONENT: Explicit export filesystem tests
// PURPOSE: Verify actual file replacement and export-copy source protection.
import Foundation
import Testing
@testable import MonoMarkCore

struct AnnotationExportWriterTests
{
    @Test func readingDataExportCannotUseAHardLinkToTheSource() throws
    {
        let source = try document()
        let link = source.deletingLastPathComponent().appendingPathComponent("hard-link.md")
        try FileManager.default.linkItem(at: source, to: link)
        #expect(throws: ReaderFailure.denied)
        {
            try AnnotationExportWriter.write(
                source: source,
                destination: link,
                notes: ReadingNotes(text: "Notes"),
                options: ReadingExportOptions(dataOnly: true)
            )
        }
    }

    @Test func readingDataExportCannotReplaceTheSourceDocument() throws
    {
        let source = try document()
        let options = ReadingExportOptions(dataOnly: true)
        #expect(throws: ReaderFailure.denied)
        {
            try AnnotationExportWriter.write(
                source: source,
                destination: source,
                notes: ReadingNotes(text: "Notes"),
                options: options
            )
        }
        #expect(try String(contentsOf: source, encoding: .utf8) == "# Original\n")
    }

    @Test func readingDataExportCannotReplaceASymlinkedSource() throws
    {
        let source = try document()
        let link = source.deletingLastPathComponent().appendingPathComponent("alias.md")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: source)
        #expect(throws: ReaderFailure.denied)
        {
            try AnnotationExportWriter.write(
                source: source,
                destination: link,
                notes: ReadingNotes(text: "Notes"),
                options: ReadingExportOptions(dataOnly: true)
            )
        }
        #expect(try String(contentsOf: source, encoding: .utf8) == "# Original\n")
    }

    @Test func notesOnlyCanBeExportedAfterTheSourceDisappears() throws
    {
        let source = try document()
        let destination = source.deletingLastPathComponent().appendingPathComponent("notes.md")
        try FileManager.default.removeItem(at: source)
        try AnnotationExportWriter.write(
            source: source,
            destination: destination,
            notes: ReadingNotes(text: "Local notes"),
            options: ReadingExportOptions(includeAnnotations: false, dataOnly: true)
        )
        #expect(try String(contentsOf: destination, encoding: .utf8).contains("Local notes"))
    }

    @Test func staleSnapshotCannotReplaceTheCurrentSource() throws
    {
        let source = try document()
        let notes = ReadingNotes(text: "My notes", sourceHash: DocumentStamp.make("# Original\n"))
        let changed = Data("# Changed after reading\n".utf8)
        try changed.write(to: source)
        #expect(throws: AnnotationFailure.sourceChanged)
        {
            try AnnotationExportWriter.write(source: source, destination: source, notes: notes)
        }
        #expect(try Data(contentsOf: source) == changed)
    }

    @Test func sourceStampUsesTheSameCanonicalTextAsTheRenderer()
    {
        #expect(DocumentStamp.make("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        #expect(DocumentStamp.make("\u{FEFF}a\r\nb\r") == DocumentStamp.make("a\nb\n"))
    }

    func document() throws -> URL
    {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("book.md")
        try "# Original\n".write(to: file, atomically: true, encoding: .utf8)
        return file
    }

    @Test func copyPreservesOriginal() throws
    {
        let source = try document()
        let destination = source.deletingLastPathComponent().appendingPathComponent("copy.md")
        try AnnotationExportWriter.write(
            source: source,
            destination: destination,
            notes: ReadingNotes(text: "My notes")
        )
        #expect(try String(contentsOf: source, encoding: .utf8) == "# Original\n")
        #expect(try String(contentsOf: destination, encoding: .utf8).contains("> My notes"))
    }

    @Test func sameFileExportReadsLatestSource() throws
    {
        let source = try document()
        try "# External update\n".write(to: source, atomically: true, encoding: .utf8)
        try AnnotationExportWriter.write(source: source, destination: source, notes: ReadingNotes(text: "My notes"))
        #expect(try String(contentsOf: source, encoding: .utf8).hasPrefix("# External update\n"))
    }

    @Test func malformedMarkersLeaveOriginalBytesUnchanged() throws
    {
        let source = try document()
        let original = Data("# Original\n<!-- monomark:reading-data:start -->".utf8)
        try original.write(to: source)
        #expect(throws: (any Error).self)
        {
            try AnnotationExportWriter.write(source: source, destination: source, notes: ReadingNotes(text: "Notes"))
        }
        #expect(try Data(contentsOf: source) == original)
    }
}
