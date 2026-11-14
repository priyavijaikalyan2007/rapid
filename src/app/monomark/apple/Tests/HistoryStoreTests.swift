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
}
