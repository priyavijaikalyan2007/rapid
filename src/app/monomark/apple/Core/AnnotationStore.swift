// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 21567cfb-f635-4ae6-ac07-2c0a0dc7fb41
// COMPONENT: MonoMark local annotations
// PURPOSE: Persist reading data separately from Markdown source.
// FLOW: Validated reading action -> local store -> native view.

import Foundation

/// Actor isolation keeps note writes off the main actor. SQLite also serializes separate windows and connections.
actor AnnotationStore
{
    private let database: SQLiteDatabase

    init(url: URL) throws
    {
        let db = try SQLiteDatabase(url: url)
        let version = try db.execute("PRAGMA user_version").first?.first.flatMap(Int.init) ?? 0
        guard version <= 1
        else
        {
            throw AnnotationFailure.unsupportedVersion
        }
        try db.execute("PRAGMA foreign_keys=ON")
        try db.execute("PRAGMA journal_mode=WAL")
        try db.transaction
        {
            try db.execute("""
                CREATE TABLE IF NOT EXISTS documents (
                    id TEXT PRIMARY KEY, path TEXT NOT NULL UNIQUE, notes TEXT NOT NULL DEFAULT '',
                    format TEXT NOT NULL DEFAULT 'markdown')
                """)
            try db.execute("""
                CREATE TABLE IF NOT EXISTS annotations (
                    document_id TEXT NOT NULL REFERENCES documents(id) ON UPDATE CASCADE ON DELETE CASCADE,
                    id TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(document_id, id))
                """)
            try db.execute("PRAGMA user_version=1")
        }
        database = db
    }

    func load(document: String, path: String) throws -> ReadingNotes
    {
        try database.transaction
        {
            try ensure(document, path)
            let row = try database.execute("SELECT notes, format FROM documents WHERE id=?", [document]).first!
            let values = try database.execute(
                "SELECT payload FROM annotations WHERE document_id=? ORDER BY rowid",
                [document]
            )
            return try ReadingNotes(
                annotations: values.map
                {
                    try JSONDecoder().decode(ReadingAnnotation.self, from: Data($0[0].utf8))
                },
                text: row[0],
                format: row[1]
            )
        }
    }

    func put(_ annotation: ReadingAnnotation, expected: ReadingAnnotation? = nil, document: String, path: String) throws
    {
        try annotation.validate()
        let payload = String(decoding: try JSONEncoder().encode(annotation), as: UTF8.self)
        try database.transaction
        {
            try ensure(document, path)
            if let expected
            {
                let previous = try database.execute(
                    "SELECT payload FROM annotations WHERE document_id=? AND id=?",
                    [document, annotation.id]
                ).first?[0]
                guard let previous,
                      try JSONDecoder().decode(ReadingAnnotation.self, from: Data(previous.utf8)) == expected
                else
                {
                    throw AnnotationFailure.notesConflict
                }
            }
            try database.execute("""
                INSERT INTO annotations VALUES(?,?,?) ON CONFLICT(document_id,id) DO UPDATE SET payload=excluded.payload
                """, [document, annotation.id, payload])
        }
    }

    func remove(_ id: String, document: String, path: String) throws
    {
        try database.transaction
        {
            try ensure(document, path)
            try database.execute("DELETE FROM annotations WHERE document_id=? AND id=?", [document, id])
        }
    }

    func writeNotes(_ text: String, format: String, expected: String, document: String, path: String) throws
    {
        guard text.utf8.count <= 1024 * 1024, ["plain", "markdown"].contains(format)
        else
        {
            throw AnnotationFailure.invalidData
        }
        try database.transaction
        {
            try ensure(document, path)
            let previous = try database.execute("SELECT notes FROM documents WHERE id=?", [document]).first?[0]
            guard previous == expected
            else
            {
                throw AnnotationFailure.notesConflict
            }
            try database.execute("UPDATE documents SET notes=?, format=? WHERE id=?", [text, format, document])
        }
    }

    private func ensure(_ id: String, _ path: String) throws
    {
        let match = try database.execute(
            "SELECT id FROM documents WHERE id=? OR path=? ORDER BY (id=?) DESC LIMIT 1",
            [id, path, id]
        ).first?[0]
        if let match
        {
            try database.execute("UPDATE documents SET id=?, path=? WHERE id=?", [id, path, match])
        }
        else
        {
            try database.execute("INSERT INTO documents(id,path) VALUES(?,?)", [id, path])
        }
    }
}
