// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 884c530b-18e9-44a5-b66f-9ce44876b174
// COMPONENT: Reading-data lifecycle tests
// PURPOSE: Verify ordered autosave, conflict recovery, and close-time flushing against SQLite.

import Foundation
import Testing
@testable import MonoMarkCore

@MainActor
struct AnnotationControllerTests
{
    func database() -> URL
    {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("annotations.sqlite")
    }

    func controller(_ url: URL) async -> AnnotationController
    {
        let model = AnnotationController(databaseURL: url)
        model.open(document: "one", path: "/book.md")
        await model.waitForLoad()
        return model
    }

    @Test func rapidNotesFlushLastEditBeforeClosing() async throws
    {
        let url = database()
        let model = await controller(url)
        model.editNotes("First edit")
        model.editNotes("Last edit", format: "plain")
        #expect(model.notesDirty)
        #expect(await model.drain())
        let saved = try await AnnotationStore(url: url).load(document: "one", path: "/book.md")
        #expect(saved.text == "Last edit")
        #expect(saved.format == "plain")
        #expect(model.pending == 0)
        #expect(!model.notesDirty)
    }

    @Test func highlightsCommentsAndDeletionSurviveReload() async throws
    {
        let model = await controller(database())
        model.selection = [TextAnchor(blockID: "b", quote: "Selected text", prefix: "", suffix: "", start: 0)]
        model.addSelection()
        var annotation = try #require(model.records.first)
        annotation.comment = "A comment"
        model.update(annotation)
        #expect(await model.drain())
        model.reload()
        await model.waitForLoad()
        #expect(model.records.first?.comment == "A comment")
        #expect(model.records.first?.updatedAt != nil)
        #expect(model.shown)
        model.remove(try #require(model.records.first))
        #expect(await model.drain())
        model.reload()
        await model.waitForLoad()
        #expect(model.records.isEmpty)
    }

    @Test func conflictingDraftBlocksClosureUntilExplicitRetry() async throws
    {
        let url = database()
        let one = await controller(url)
        let two = await controller(url)
        one.editNotes("First window")
        #expect(await one.drain())
        two.editNotes("Second window draft")
        #expect(!(await two.drain()))
        #expect(two.text == "Second window draft")
        #expect(two.error != nil)
        two.retryDraft()
        #expect(await two.drain())
        #expect(two.error == nil)
        #expect(try await AnnotationStore(url: url).load(document: "one", path: "/book.md")
            .text == "Second window draft")
    }

    @Test func explicitReloadRecoversSavedNotesAfterConflict() async throws
    {
        let url = database()
        let one = await controller(url)
        let two = await controller(url)
        one.editNotes("Saved")
        #expect(await one.drain())
        two.editNotes("Discarded draft")
        #expect(!(await two.drain()))
        two.reload()
        await two.waitForLoad()
        #expect(two.text == "Saved")
        #expect(await two.drain())
    }

    @Test func oversizedDraftRemainsVisibleAndBlocksClosure() async throws
    {
        let model = await controller(database())
        let text = String(repeating: "x", count: 1024 * 1024 + 1)
        model.editNotes(text)
        #expect(!(await model.drain()))
        #expect(model.text == text)
        #expect(model.hasFailedEdits)
    }

    @Test func unavailableStoreDoesNotPreventReadOnlyViewing() async throws
    {
        let url = database()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("corrupt".utf8).write(to: url)
        let model = AnnotationController(databaseURL: url)
        model.open(document: "one", path: "/book.md")
        await model.waitForLoad()
        #expect(!model.ready)
        #expect(model.error != nil)
        #expect(await model.drain())
        model.addSelection()
        model.editNotes("Ignored")
        #expect(model.records.isEmpty)
    }

    @Test func editsDuringAnInFlightFlushAreIncludedBeforeClosure() async throws
    {
        let url = database()
        let model = await controller(url)
        let blocker = try SQLiteDatabase(url: url)
        try blocker.execute("BEGIN IMMEDIATE")
        defer { _ = try? blocker.execute("ROLLBACK") }
        model.editNotes("First edit")
        let closing = Task
        {
            await model.drain()
        }
        try await Task.sleep(for: .milliseconds(20))
        try #require(model.pending > 0)
        model.editNotes("Edit during closure")
        try blocker.execute("COMMIT")
        #expect(await closing.value)
        let saved = try await AnnotationStore(url: url).load(document: "one", path: "/book.md")
        #expect(saved.text == "Edit during closure")
    }

    @Test func identityRefreshPreservesPendingNotesBeforeRename() async throws
    {
        let model = await controller(database())
        let token = model.documentToken
        model.editNotes("Notes survive replacement and rename.")

        model.adoptIdentity("replacement", path: "/book.md")
        #expect(await model.drain())
        #expect(model.documentToken == token)
        model.open(document: "replacement", path: "/renamed.md")
        await model.waitForLoad()

        #expect(model.text == "Notes survive replacement and rename.")
    }

    @Test func identityRefreshKeepsQueuedAnnotationsAndCurrentSelection() async throws
    {
        let model = await controller(database())
        let anchor = TextAnchor(blockID: "heading", quote: "Selected", prefix: "", suffix: "", start: 0)
        model.selection = [anchor]
        model.addSelection()
        model.selection = [anchor]

        model.adoptIdentity("replacement", path: "/book.md")
        #expect(await model.drain())
        #expect(model.selection == [anchor])
        model.open(document: "replacement", path: "/renamed.md")
        await model.waitForLoad()

        #expect(model.records.count == 1)
    }
}
