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
