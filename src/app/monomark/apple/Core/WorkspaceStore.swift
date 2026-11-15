// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 584e6c0a-1bba-4417-b50c-f2b8ff641e33
// COMPONENT: Persistent folder workspaces
// PURPOSE: Deduplicate granted folders and retain last-document metadata through atomic SQLite updates.
import Foundation

actor WorkspaceStore
{
    private let database: SQLiteDatabase

    init(url: URL) throws
    {
        let db = try SQLiteDatabase(url: url)
        let version = try db.execute("PRAGMA user_version").first?.first.flatMap(Int.init) ?? 0
        guard version <= 1
        else
        {
            throw WorkspaceFailure.unsupportedVersion
        }
        try db.execute("PRAGMA journal_mode=WAL")
        try db.transaction
        {
            try db.execute("""
                CREATE TABLE IF NOT EXISTS workspaces (
                    id TEXT PRIMARY KEY, accessed REAL NOT NULL, payload TEXT NOT NULL)
                """)
            try db.execute("CREATE INDEX IF NOT EXISTS workspaces_recent ON workspaces(accessed DESC)")
            try db.execute("PRAGMA user_version=1")
        }
        database = db
    }

    func remember(_ value: WorkspaceRecord) throws
    {
        try value.validate()
        try database.transaction
        {
            var record = value
            if let previous = try find(folder: value.folder)
            {
                if previous.accessedAt > value.accessedAt
                {
                    return
                }
                record.lastDocument = value.lastDocument ?? previous.lastDocument
                record.bookmark = value.bookmark ?? previous.bookmark
            }
            let payload = try JSONEncoder().encode(record)
            guard payload.count <= 4 * 1024 * 1024
            else
            {
                throw WorkspaceFailure.invalidRecord
            }
            try database.execute("""
                INSERT INTO workspaces VALUES(?,?,?) ON CONFLICT(id) DO UPDATE SET
                    accessed=excluded.accessed, payload=excluded.payload
                """, [record.id, String(record.accessedAt), String(decoding: payload, as: UTF8.self)])
        }
    }

    func recent(limit: Int = 40) throws -> [WorkspaceRecord]
    {
        try database.execute(
            "SELECT payload FROM workspaces ORDER BY accessed DESC LIMIT ?",
            [String(min(200, max(1, limit)))]
        ).map
        {
            try decode($0[0])
        }
    }

    func find(folder: URL) throws -> WorkspaceRecord?
    {
        let id = WorkspaceRecord(folder: folder).id
        return try database.execute("SELECT payload FROM workspaces WHERE id=?", [id]).first.map
        {
            try decode($0[0])
        }
    }

    func remove(_ id: String) throws
    {
        try database.execute("DELETE FROM workspaces WHERE id=?", [id])
    }

    private func decode(_ value: String) throws -> WorkspaceRecord
    {
        guard value.utf8.count <= 4 * 1024 * 1024
        else
        {
            throw WorkspaceFailure.invalidRecord
        }
        let record = try JSONDecoder().decode(WorkspaceRecord.self, from: Data(value.utf8))
        try record.validate()
        return record
    }
}
