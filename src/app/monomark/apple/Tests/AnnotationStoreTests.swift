// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 96974339-ea9a-497c-8d71-879b3a6d8e74
// COMPONENT: Annotation persistence contracts
// PURPOSE: Verify actual SQLite recovery, concurrent-note safety, and document replacement.

import Foundation
import SQLite3
import Testing
@testable import MonoMarkCore

struct AnnotationStoreTests
{
    func database() -> URL
    {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("annotations.sqlite")
    }

    func annotation() -> ReadingAnnotation
    {
        ReadingAnnotation(anchors: [TextAnchor(
            blockID: "block-1",
            quote: "A sentence",
            prefix: "",
            suffix: ".",
            start: 0
        )])
    }

    @Test func persistsAnnotationsAndNotesAcrossReopening() async throws
    {
        let url = database()
        let store = try AnnotationStore(url: url)
        let mark = annotation()
        try await store.put(mark, document: "one", path: "/book.md")
        try await store.writeNotes("# My notes", format: "markdown", expected: "", document: "one", path: "/book.md")
        let saved = try await AnnotationStore(url: url).load(document: "one", path: "/book.md")
        #expect(saved.annotations == [mark])
        #expect(saved.text == "# My notes")
        #expect(saved.format == "markdown")
    }

    @Test func atomicSourceReplacementRetainsReadingData() async throws
    {
        let store = try AnnotationStore(url: database())
        try await store.put(annotation(), document: "old-inode", path: "/book.md")
        let saved = try await store.load(document: "new-inode", path: "/book.md")
        #expect(saved.annotations.count == 1)
    }

    @Test func renamedDocumentRetainsIdentity() async throws
    {
        let store = try AnnotationStore(url: database())
        try await store.put(annotation(), document: "one", path: "/old.md")
        #expect(try await store.load(document: "one", path: "/new.md").annotations.count == 1)
    }

    @Test func annotationsRemainIndependentOfNotesAndOtherDocuments() async throws
    {
        let store = try AnnotationStore(url: database())
        var mark = annotation()
        try await store.put(mark, document: "one", path: "/one.md")
        mark.comment = "Comment changed"
        mark.color = "blue"
        try await store.put(mark, document: "one", path: "/one.md")
        #expect(try await store.load(document: "one", path: "/one.md").annotations == [mark])
        #expect(try await store.load(document: "two", path: "/two.md").annotations.isEmpty)
        try await store.remove(mark.id, document: "one", path: "/one.md")
        #expect(try await store.load(document: "one", path: "/one.md").annotations.isEmpty)
    }

    @Test func staleNotesCannotOverwriteAnotherWindow() async throws
    {
        let url = database()
        let one = try AnnotationStore(url: url)
        let two = try AnnotationStore(url: url)
        try await one.writeNotes("First", format: "plain", expected: "", document: "one", path: "/book.md")
        await #expect(throws: (any Error).self)
        {
            try await two.writeNotes("Stale", format: "plain", expected: "", document: "one", path: "/book.md")
        }
        #expect(try await one.load(document: "one", path: "/book.md").text == "First")
    }

    @Test func invalidAnnotationIsRejected() async throws
    {
        let store = try AnnotationStore(url: database())
        var mark = annotation()
        mark.color = "javascript:bad"
        await #expect(throws: (any Error).self)
        {
            try await store.put(mark, document: "one", path: "/book.md")
        }
    }

    @Test func futureSchemaIsNotDowngraded() throws
    {
        let url = database()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var db: OpaquePointer?
        sqlite3_open(url.path, &db)
        sqlite3_exec(db, "PRAGMA user_version=999", nil, nil, nil)
        sqlite3_close(db)
        #expect(throws: (any Error).self) { _ = try AnnotationStore(url: url) }
    }

    @Test func staleAnnotationCannotReplaceAnotherComment() async throws
    {
        let store = try AnnotationStore(url: database())
        let original = annotation()
        try await store.put(original, document: "one", path: "/book.md")
        var changed = original
        changed.comment = "New comment"
        try await store.put(changed, expected: original, document: "one", path: "/book.md")
        await #expect(throws: (any Error).self)
        {
            try await store.put(original, expected: original, document: "one", path: "/book.md")
        }
        #expect(try await store.load(document: "one", path: "/book.md").annotations.first?.comment == "New comment")
    }

    @Test func corruptDatabaseFailsWithoutReplacingIt() throws
    {
        let url = database()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let original = Data("not a database".utf8)
        try original.write(to: url)
        #expect(throws: (any Error).self) { _ = try AnnotationStore(url: url) }
        #expect(try Data(contentsOf: url) == original)
    }

    @Test func invalidModificationTimestampIsRejected() async throws
    {
        let store = try AnnotationStore(url: database())
        var mark = annotation()
        mark.updatedAt = .nan
        await #expect(throws: (any Error).self)
        {
            try await store.put(mark, document: "one", path: "/book.md")
        }
    }
}
