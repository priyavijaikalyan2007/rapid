// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: a8541581-adbe-462c-a5cb-2acbc14ae8b8
// COMPONENT: Folder workspace metadata
// PURPOSE: Remember authorized folder locations and their most recent document without copying source.
import Foundation

struct WorkspaceRecord: Codable, Equatable, Identifiable, Sendable
{
    var path: String
    var bookmark: Data?
    var lastDocument: ReadingState?
    var accessedAt: Double
    var folder: URL
    {
        URL(fileURLWithPath: path)
    }

    var id: String
    {
        folder.standardizedFileURL.resolvingSymlinksInPath().path
    }

    var title: String
    {
        folder.lastPathComponent.isEmpty ? path : folder.lastPathComponent
    }

    init(
        folder: URL,
        bookmark: Data? = nil,
        document: ReadingState? = nil,
        accessedAt: Double = Date().timeIntervalSince1970
    )
    {
        path = folder.isFileURL ? folder.standardizedFileURL.path : ""
        self.bookmark = bookmark
        lastDocument = document
        self.accessedAt = accessedAt
    }

    /// A stale last-document checkpoint must never become the fallback file's reading state.
    func resume(in folder: URL, resolvedFile: URL? = nil) -> ReadingState?
    {
        guard var document = lastDocument
        else
        {
            return nil
        }
        let file = resolvedFile ?? URL(fileURLWithPath: document.path)
        guard DocumentAccess.contains(file, in: folder),
              (try? file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        else
        {
            return nil
        }
        document.path = file.path
        document.rootPath = folder.path
        return document
    }

    func validate() throws
    {
        guard path.hasPrefix("/"), path.utf8.count <= 16384, accessedAt.isFinite,
              (bookmark?.count ?? 0) <= 1024 * 1024
        else
        {
            throw WorkspaceFailure.invalidRecord
        }
        if let lastDocument
        {
            guard lastDocument.path.hasPrefix("/"),
                  DocumentAccess.contains(URL(fileURLWithPath: lastDocument.path), in: folder),
                  URL(fileURLWithPath: lastDocument.path).standardizedFileURL != folder.standardizedFileURL
            else
            {
                throw WorkspaceFailure.invalidRecord
            }
        }
    }
}
