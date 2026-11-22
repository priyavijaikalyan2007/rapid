// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 0ab3efcf-607d-4c4a-a44d-41d062c10648
// COMPONENT: Folder workspace persistence tests
// PURPOSE: Verify canonical identity, stale-write protection, recovery, and folder boundaries in real SQLite.
import Foundation
import Testing
@testable import MonoMarkCore

struct WorkspaceStoreTests
{
    @Test func remembersDistinctFoldersAndRecoversTheirDocuments() async throws
    {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let database = base.appendingPathComponent("workspaces.sqlite")
        let first = base.appendingPathComponent("One")
        let second = base.appendingPathComponent("Two")
        let store = try WorkspaceStore(url: database)
        let document = ReadingState(id: "doc", path: first.appendingPathComponent("read.md").path, accessedAt: 10)
        try await store.remember(WorkspaceRecord(
            folder: first,
            bookmark: Data([1, 2]),
            document: document,
            accessedAt: 10
        ))
        try await store.remember(WorkspaceRecord(folder: second, accessedAt: 20))
        let reopened = try WorkspaceStore(url: database)
        let records = try await reopened.recent()
        #expect(records.map(\.path) == [second.path, first.path])
        #expect(try await reopened.find(folder: first)?.lastDocument == document)
        #expect(try await reopened.find(folder: first)?.bookmark == Data([1, 2]))
    }

    @Test func canonicalFoldersDeduplicateAndStaleWritesCannotReplaceState() async throws
    {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let store = try WorkspaceStore(url: base.appendingPathComponent("workspaces.sqlite"))
        let folder = base.appendingPathComponent("One")
        let document = ReadingState(id: "doc", path: folder.appendingPathComponent("read.md").path, accessedAt: 20)
        try await store.remember(WorkspaceRecord(folder: folder, document: document, accessedAt: 20))
        try await store.remember(WorkspaceRecord(folder: folder.appendingPathComponent("../One"), accessedAt: 10))
        try await store.remember(WorkspaceRecord(folder: folder, accessedAt: 30))
        #expect(try await store.recent().count == 1)
        #expect(try await store.find(folder: folder)?.lastDocument == document)
        #expect(try await store.find(folder: folder)?.accessedAt == 30)
    }

    @Test func invalidWorkspaceAndOutsideDocumentAreRejected() async throws
    {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let store = try WorkspaceStore(url: base.appendingPathComponent("workspaces.sqlite"))
        let outside = ReadingState(id: "bad", path: base.appendingPathComponent("Other/doc.md").path, accessedAt: 1)
        await #expect(throws: WorkspaceFailure.self)
        {
            try await store.remember(WorkspaceRecord(folder: base.appendingPathComponent("One"), document: outside))
        }
        await #expect(throws: WorkspaceFailure.self)
        {
            try await store.remember(WorkspaceRecord(folder: base, accessedAt: .nan))
        }
        #expect(try await store.recent().isEmpty)
    }

    @Test func forgettingOnlyRemovesWorkspaceMetadata() async throws
    {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let store = try WorkspaceStore(url: base.appendingPathComponent("workspaces.sqlite"))
        let folder = base.appendingPathComponent("One")
        let record = WorkspaceRecord(folder: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let source = folder.appendingPathComponent("read.md")
        try Data("Original source".utf8).write(to: source)
        try await store.remember(record)
        try await store.remove(record.id)
        #expect(try await store.recent().isEmpty)
        #expect(try String(contentsOf: source, encoding: .utf8) == "Original source")
    }

    @Test func unsupportedSchemaDoesNotLoseItsVersion() async throws
    {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let file = base.appendingPathComponent("future.sqlite")
        let db = try SQLiteDatabase(url: file)
        try db.execute("PRAGMA user_version=99")
        #expect(throws: WorkspaceFailure.self) { try WorkspaceStore(url: file) }
        #expect(try db.execute("PRAGMA user_version").first?.first == "99")
    }
}

extension WorkspaceStoreTests
{
    @MainActor @Test func sharedListRefreshesAndForgettingKeepsNotesSeparate() async throws
    {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let file = base.appendingPathComponent("workspaces.sqlite")
        let library = WorkspaceLibrary(databaseURL: file)
        let record = WorkspaceRecord(folder: base.appendingPathComponent("Folder"))
        await library.remember(record)
        #expect(library.records.count == 1)
        #expect(library.records.first?.title == "Folder")
        await library.refresh()
        await library.forget(record)
        #expect(library.records.isEmpty)
        #expect(library.error == nil)
    }

    @MainActor @Test func emptyWorkspaceDetachesNotesAfterTheySave() async throws
    {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let file = base.appendingPathComponent("notes.sqlite")
        let notes = AnnotationController(databaseURL: file)
        notes.open(document: "doc", path: "/folder/read.md")
        await notes.waitForLoad()
        notes.editNotes("Preserve this note before workspace switching.")
        #expect(await notes.drain())
        notes.detach()
        #expect(notes.text.isEmpty)
        #expect(notes.ready == false)
        notes.open(document: "doc", path: "/folder/read.md")
        await notes.waitForLoad()
        #expect(notes.text == "Preserve this note before workspace switching.")
    }
}

extension WorkspaceStoreTests
{
    @Test func resumingRequiresAnAvailableFileInsideTheWorkspace() throws
    {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let file = base.appendingPathComponent("reading.md")
        try Data("# Reading".utf8).write(to: file)
        var document = ReadingState(id: "reading", path: file.path, accessedAt: 1)
        document.anchor = "saved-heading"
        let record = WorkspaceRecord(folder: base, document: document)
        #expect(record.resume(in: base)?.anchor == "saved-heading")
        try FileManager.default.removeItem(at: file)
        #expect(record.resume(in: base) == nil)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)
        #expect(record.resume(in: base) == nil)
        #expect(record.resume(in: base.appendingPathComponent("other"), resolvedFile: file) == nil)
    }

    @Test func renewedBookmarksCanResumeAMovedFolder() throws
    {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let moved = base.appendingPathComponent("Moved")
        try FileManager.default.createDirectory(at: moved, withIntermediateDirectories: true)
        let file = moved.appendingPathComponent("reading.md")
        try Data("# Reading".utf8).write(to: file)
        let old = base.appendingPathComponent("Old")
        let record = WorkspaceRecord(
            folder: old,
            document: ReadingState(id: "reading", path: old.appendingPathComponent("reading.md").path, accessedAt: 1)
        )
        let resumed = record.resume(in: moved, resolvedFile: file)
        #expect(resumed?.path == file.path)
        #expect(resumed?.rootPath == moved.path)
    }

    @MainActor @Test func unsupportedStoreKeepsItsRecoveryMessage() async throws
    {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let file = base.appendingPathComponent("future.sqlite")
        let db = try SQLiteDatabase(url: file)
        try db.execute("PRAGMA user_version=99")
        let library = WorkspaceLibrary(databaseURL: file)
        await library.refresh()
        #expect(library.error?.contains("newer Monoleaf") == true)
        #expect(library.records.isEmpty)
    }
}

extension WorkspaceStoreTests
{
    @MainActor @Test func documentChangesExposeANewEditorBoundary() async throws
    {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: base) }
        let notes = AnnotationController(databaseURL: base.appendingPathComponent("notes.sqlite"))
        let empty = notes.documentToken
        notes.open(document: "one", path: "/one.md")
        await notes.waitForLoad()
        let loaded = notes.documentToken
        #expect(loaded != empty)
        #expect(await notes.drain())
        notes.detach()
        #expect(notes.documentToken != loaded)
        notes.editNotes("An empty workspace must not accept an edit.")
        #expect(notes.text.isEmpty)
    }

    @Test func newDocumentsUseAppDefaultsInsteadOfThePreviousFile() throws
    {
        var defaults = ReaderPreferences()
        defaults.fontFamily = "JetBrains Mono"
        defaults.palette.preset("forest", dark: true)
        var saved = ReaderPreferences()
        saved.fontFamily = "Atkinson Hyperlegible"
        let data = try JSONEncoder().encode(defaults)
        #expect(ReaderPreferences.forDocument(saved: nil, defaultsData: data) == defaults)
        #expect(ReaderPreferences.forDocument(saved: saved, defaultsData: data) == saved)
        #expect(ReaderPreferences.forDocument(saved: nil, defaultsData: Data("bad".utf8)) == ReaderPreferences())
    }
}
