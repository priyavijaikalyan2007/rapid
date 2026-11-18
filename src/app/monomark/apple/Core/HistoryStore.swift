// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: ab27f76e-65d1-4249-bf87-b41ac99e104d
// Created: 2026
// COMPONENT: MonoMark core
// PURPOSE: Persist paged reading history through atomic SQLite statements.
// RELATES: MonoMarkCoreTests
// FLOW: Validated input -> local processing -> typed result.

import Foundation
import SQLite3

/// Serialized SQLite access keeps the complete history on disk while paging only requested rows into memory.
final class HistoryStore: @unchecked Sendable
{
    private var database: OpaquePointer?
    private let lock = NSRecursiveLock()
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init(url: URL) throws
    {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard sqlite3_open_v2(
            url.path,
            &database,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        ) == SQLITE_OK else
        {
            throw ReaderFailure.invalidStore
        }
        sqlite3_busy_timeout(database, 3000)
        do
        {
            try execute("PRAGMA journal_mode=WAL")
            try execute(
                """
                CREATE TABLE IF NOT EXISTS history(id TEXT PRIMARY KEY, path TEXT NOT NULL, accessed REAL NOT \
                NULL, payload TEXT NOT NULL)
                """
            )
            try execute("CREATE INDEX IF NOT EXISTS history_recent ON history(accessed DESC)")
            try execute("CREATE INDEX IF NOT EXISTS history_path ON history(path,accessed DESC)")
            try execute("PRAGMA user_version=1")
        }
        catch
        {
            sqlite3_close(database)
            database = nil
            throw error
        }
    }

    deinit { sqlite3_close(database) }

    func record(_ state: ReadingState) throws
    {
        guard state.accessedAt.isFinite
        else
        {
            throw ReaderFailure.invalidStore
        }
        guard let payload = String(data: try JSONEncoder().encode(state), encoding: .utf8)
        else
        {
            throw ReaderFailure.invalidStore
        }
        try lock.withLock
        {
            try writeTransaction(state, payload: payload)
        }
    }

    /// Recover replacement files by the already-authorized path. Identity still follows a renamed file.
    func state(id: String, path: String? = nil) throws -> ReadingState?
    {
        try lock.withLock
        {
            if let exact = try rows("SELECT payload FROM history WHERE id=?", arguments: [id]).first
            {
                return exact
            }
            guard let path
            else
            {
                return nil
            }
            return try rows(
                "SELECT payload FROM history WHERE path=? ORDER BY accessed DESC LIMIT 1",
                arguments: [path]
            ).first
        }
    }

    private func writeTransaction(_ state: ReadingState, payload: String) throws
    {
        try execute("BEGIN IMMEDIATE")
        do
        {
            try replaceLatest(state, payload: payload)
            try execute("COMMIT")
        }
        catch
        {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func replaceLatest(_ state: ReadingState, payload: String) throws
    {
        let latest = try rows(
            "SELECT payload FROM history WHERE id=? OR path=? ORDER BY accessed DESC LIMIT 1",
            arguments: [state.id, state.path]
        ).first
        guard latest?.accessedAt ?? -.infinity <= state.accessedAt
        else
        {
            return
        }
        try execute("DELETE FROM history WHERE path=? AND id<>?", arguments: [state.path, state.id])
        let sql = """
            INSERT INTO history VALUES(?,?,?,?) ON CONFLICT(id) DO UPDATE SET path=excluded.path, \
            accessed=excluded.accessed, payload=excluded.payload WHERE excluded.accessed>=history.accessed
            """
        try execute(sql, arguments: [state.id, state.path, String(state.accessedAt), payload])
    }

    func page(query: String, offset: Int, limit: Int) throws -> [ReadingState]
    {
        try lock.withLock
        {
            try rows(
                """
                SELECT payload FROM history WHERE instr(lower(path),lower(?))>0 ORDER BY accessed DESC LIMIT ? \
                OFFSET ?
                """,
                arguments: [String(query.prefix(200)), String(min(max(limit, 1), 200)), String(max(offset, 0))]
            )
        }
    }

    func forget(_ id: String) throws
    {
        try lock.withLock
        {
            try execute("DELETE FROM history WHERE id=?", arguments: [id])
        }
    }

    func clear() throws
    {
        try lock.withLock
        {
            try execute("DELETE FROM history")
        }
    }

    private func prepare(_ sql: String, arguments: [String]) throws -> OpaquePointer
    {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement
        else
        {
            throw ReaderFailure.invalidStore
        }
        for (index, value) in arguments.enumerated()
        {
            _ = value.withCString
            {
                sqlite3_bind_text(statement, Int32(index + 1), $0, -1, transient)
            }
        }
        return statement
    }

    private func execute(_ sql: String, arguments: [String] = []) throws
    {
        let statement = try prepare(sql, arguments: arguments)
        defer { sqlite3_finalize(statement) }
        let status = sqlite3_step(statement)
        guard status == SQLITE_DONE || status == SQLITE_ROW
        else
        {
            throw ReaderFailure.invalidStore
        }
    }

    private func rows(_ sql: String, arguments: [String]) throws -> [ReadingState]
    {
        let statement = try prepare(sql, arguments: arguments)
        defer { sqlite3_finalize(statement) }
        var result: [ReadingState] = []
        var status = sqlite3_step(statement)
        while status == SQLITE_ROW
        {
            guard let bytes = sqlite3_column_text(statement, 0)
            else
            {
                throw ReaderFailure.invalidStore
            }
            result.append(try JSONDecoder().decode(ReadingState.self, from: Data(String(cString: bytes).utf8)))
            status = sqlite3_step(statement)
        }
        guard status == SQLITE_DONE
        else
        {
            throw ReaderFailure.invalidStore
        }
        return result
    }
}
