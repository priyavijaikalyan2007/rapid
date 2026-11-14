// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: d8fcc337-8fc6-432a-b917-7f2a618fd64d
// COMPONENT: MonoMark local annotations
// PURPOSE: Persist reading data separately from Markdown source.
// FLOW: Validated reading action -> local store -> native view.

import Foundation
import SQLite3

/// A locked connection commits each related update as one SQLite transaction.
final class SQLiteDatabase: @unchecked Sendable
{
    private var handle: OpaquePointer?
    private let lock = NSRecursiveLock()
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init(url: URL) throws
    {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard sqlite3_open_v2(
            url.path,
            &handle,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        ) == SQLITE_OK else
        {
            sqlite3_close(handle)
            handle = nil
            throw ReaderFailure.invalidStore
        }
        sqlite3_busy_timeout(handle, 3000)
    }

    deinit { sqlite3_close(handle) }

    func transaction<T>(_ operation: () throws -> T) throws -> T
    {
        try lock.withLock
        {
            try execute("BEGIN IMMEDIATE")
            do
            {
                let result = try operation()
                try execute("COMMIT")
                return result
            }
            catch
            {
                _ = try? execute("ROLLBACK")
                throw error
            }
        }
    }

    @discardableResult
    func execute(_ sql: String, _ values: [String] = []) throws -> [[String]]
    {
        try lock.withLock
        {
            let statement = try prepare(sql, values)
            defer { sqlite3_finalize(statement) }
            var rows: [[String]] = []
            var status = sqlite3_step(statement)
            while status == SQLITE_ROW
            {
                var row: [String] = []
                for index in 0 ..< sqlite3_column_count(statement)
                {
                    let length = Int(sqlite3_column_bytes(statement, index))
                    let bytes = sqlite3_column_text(statement, index)
                    row
                        .append(bytes
                            .map
                            {
                                String(decoding: UnsafeBufferPointer(start: $0, count: length), as: UTF8.self)
                            } ?? "")
                }
                rows.append(row)
                status = sqlite3_step(statement)
            }
            guard status == SQLITE_DONE
            else
            {
                throw ReaderFailure.invalidStore
            }
            return rows
        }
    }

    private func prepare(_ sql: String, _ values: [String]) throws -> OpaquePointer
    {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK, let statement
        else
        {
            throw ReaderFailure.invalidStore
        }
        for (index, value) in values.enumerated()
        {
            let status = value.withCString
            {
                sqlite3_bind_text(statement, Int32(index + 1), $0, Int32(value.utf8.count), transient)
            }
            guard status == SQLITE_OK
            else
            {
                sqlite3_finalize(statement)
                throw ReaderFailure.invalidStore
            }
        }
        return statement
    }
}
