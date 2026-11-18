// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: d1456c4d-c632-4c09-bf10-1aa67c57bf62
// Created: 2026
// COMPONENT: Reading state persistence tests
// PURPOSE: Reading state persistence tests.
// RELATES: specs/monomark.implementation.md
// FLOW: Input -> validated processing -> result.

import Foundation
import Testing
@testable import MonoMarkCore

/// Exercise actual SQLite recovery, paging, and stale-checkpoint protection.
struct HistoryStoreTests
{
    func database() throws -> URL
    {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent("history.sqlite")
    }

    func record(_ id: String = "one", time: Double = 10) -> ReadingState
    {
        ReadingState(id: id, path: "/tmp/\(id).md", accessedAt: time)
    }

    @Test func persistsAcrossReopening() throws
    {
        let url = try database()
        var state = record()
        state.anchor = "heading"
        try HistoryStore(url: url).record(state)
        #expect(try HistoryStore(url: url).state(id: "one")?.anchor == "heading")
    }

    @Test func rejectsStaleCheckpoint() throws
    {
        let store = try HistoryStore(url: database())
        try store.record(record(time: 20))
        try store.record(record(time: 10))
        #expect(try store.state(id: "one")?.accessedAt == 20)
    }

    @Test func pagesCompleteHistory() throws
    {
        let store = try HistoryStore(url: database())
        for index in 0 ..< 160
        {
            try store.record(record("file-\(index)", time: Double(index)))
        }
        #expect(try store.page(query: "", offset: 150, limit: 20).count == 10)
    }

    @Test func searchTreatsWildcardAsLiteral() throws
    {
        let store = try HistoryStore(url: database())
        try store.record(record("normal"))
        #expect(try store.page(query: "%", offset: 0, limit: 20).isEmpty)
    }

    @Test func forgetDoesNotDeleteSource() throws
    {
        let url = try database()
        let source = url.deletingLastPathComponent().appendingPathComponent("book.md")
        try "# Book".write(to: source, atomically: true, encoding: .utf8)
        let store = try HistoryStore(url: url)
        var state = record()
        state.path = source.path
        try store.record(state)
        try store.forget("one")
        #expect(FileManager.default.fileExists(atPath: source.path))
        #expect(try store.state(id: "one") == nil)
    }

    @Test func clearRemovesAllRecords() throws
    {
        let store = try HistoryStore(url: database())
        try store.record(record())
        try store.clear()
        #expect(try store.page(query: "", offset: 0, limit: 20).isEmpty)
    }

    @Test func corruptStoreFailsVisibly() throws
    {
        let url = try database()
        try Data("not sqlite".utf8).write(to: url)
        #expect(throws: (any Error).self) { _ = try HistoryStore(url: url) }
    }

    @Test func replacementKeepsOneHistoryRow() throws
    {
        let store = try HistoryStore(url: database())
        let old = record("old", time: 10)
        var replacement = record("new", time: 20)
        replacement.path = old.path
        try store.record(old)

        try store.record(replacement)

        #expect(try store.page(query: "", offset: 0, limit: 20) == [replacement])
    }

    @Test func staleIdentityCannotReplaceNewerVisit() throws
    {
        let store = try HistoryStore(url: database())
        var latest = record("new", time: 20)
        let stale = record("old", time: 10)
        latest.path = stale.path
        try store.record(latest)

        try store.record(stale)

        #expect(try store.page(query: "", offset: 0, limit: 20) == [latest])
    }

    @Test func atomicReplacementRecoversSavedMetadata() throws
    {
        let url = try database()
        let source = url.deletingLastPathComponent().appendingPathComponent("book.md")
        try Data("# Before".utf8).write(to: source, options: .atomic)
        let store = try HistoryStore(url: url)
        var saved = record(try DocumentAccess.identity(source))
        saved.path = source.path
        saved.anchor = "chapter"
        saved.zoom = 1.5
        saved.preferences = ReaderPreferences()
        saved.preferences?.bodySize = 19
        try store.record(saved)

        try Data("# After".utf8).write(to: source, options: .atomic)
        let recovered = try HistoryStore(url: url).state(id: DocumentAccess.identity(source), path: source.path)

        #expect(recovered == saved)
    }

    @Test func identityLookupSurvivesRename() throws
    {
        let store = try HistoryStore(url: database())
        let saved = record()
        try store.record(saved)

        #expect(try store.state(id: saved.id, path: "/tmp/renamed.md") == saved)
    }

    @Test func unknownIdentityAndPathHaveNoState() throws
    {
        let store = try HistoryStore(url: database())
        try store.record(record())

        #expect(try store.state(id: "unseen", path: "/tmp/unseen.md") == nil)
    }

    @Test func forgottenVisitsCannotReturnFromAnotherWindow() throws
    {
        let url = try database()
        let first = try HistoryStore(url: url)
        let other = try HistoryStore(url: url)
        let saved = record(time: Date().timeIntervalSince1970 - 10)
        try first.record(saved)
        try first.forget(saved.id)

        try other.record(saved)

        #expect(try first.page(query: "", offset: 0, limit: 20).isEmpty)
    }

    @Test func clearRejectsPreviouslyQueuedWritesAfterReopeningTheStore() throws
    {
        let url = try database()
        let store = try HistoryStore(url: url)
        let saved = record(time: Date().timeIntervalSince1970 - 10)
        try store.record(saved)
        try store.clear()

        try HistoryStore(url: url).record(saved)

        #expect(try store.page(query: "", offset: 0, limit: 20).isEmpty)
    }

    @Test func replacementIdentityCannotReviveADeletedPath() throws
    {
        let store = try HistoryStore(url: database())
        var old = record("old", time: Date().timeIntervalSince1970 - 20)
        let latest = record("new", time: Date().timeIntervalSince1970 - 10)
        old.path = latest.path
        try store.record(latest)
        try store.forget(latest.id)

        try store.record(old)

        #expect(try store.page(query: "", offset: 0, limit: 20).isEmpty)
    }

    @Test func explicitLaterVisitsCanReenterHistoryAfterDeletion() throws
    {
        let store = try HistoryStore(url: database())
        let old = record(time: Date().timeIntervalSince1970 - 10)
        try store.record(old)
        try store.forget(old.id)
        let newer = record(time: Date().timeIntervalSince1970 + 1)

        try store.record(newer)

        #expect(try store.state(id: newer.id) == newer)
    }

    @Test func checkpointsWithinOneVisitCannotRewindSavedPosition() throws
    {
        let store = try HistoryStore(url: database())
        let stale = try stampedRecord(anchor: "older", stamp: 100)
        let latest = try stampedRecord(anchor: "latest", stamp: 200)
        try store.record(latest)

        try store.record(stale)

        #expect(try store.state(id: latest.id)?.anchor == "latest")
    }

    private func stampedRecord(anchor: String, stamp: Double) throws -> ReadingState
    {
        var saved = record()
        saved.anchor = anchor
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(saved)) as? [String: Any])
        json["updatedAt"] = stamp
        return try JSONDecoder().decode(ReadingState.self, from: JSONSerialization.data(withJSONObject: json))
    }

    @Test func additiveHistoryMigrationPreservesSavedPositions() throws
    {
        let url = try database()
        let saved = record()
        try HistoryStore(url: url).record(saved)
        let db = try SQLiteDatabase(url: url)
        try db.execute("DROP TABLE history_barriers")
        try db.execute("PRAGMA user_version=1")

        let migrated = try HistoryStore(url: url)

        #expect(try migrated.state(id: saved.id) == saved)
        #expect(try db.execute("PRAGMA user_version").first?.first == "2")
    }

    @Test func futureHistorySchemaIsRejectedWithoutChangingItsVersion() throws
    {
        let url = try database()
        let db = try SQLiteDatabase(url: url)
        try db.execute("PRAGMA user_version=99")

        #expect(throws: ReaderFailure.self) { _ = try HistoryStore(url: url) }
        #expect(try db.execute("PRAGMA user_version").first?.first == "99")
    }
}
