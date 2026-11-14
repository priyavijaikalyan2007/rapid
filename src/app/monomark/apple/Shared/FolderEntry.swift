// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 550d32b9-cb04-474d-af9a-74e4827bce28
// Created: 2026
// COMPONENT: MonoMark native UI
// PURPOSE: Enumerate folder trees without recursively loading document contents.
// RELATES: MonoMark product and implementation specifications
// FLOW: Native command -> session -> validated renderer bridge.

import Foundation

/// Lazy folder nodes enumerate names only and never parse sibling documents.
struct FolderEntry: Identifiable
{
    var url: URL
    var isFolder: Bool
    var id: String
    {
        url.path
    }

    var title: String
    {
        url.lastPathComponent
    }

    static func children(of url: URL) throws -> [FolderEntry]
    {
        try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        )
        .compactMap
        { child in
            let values = try child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard values.isSymbolicLink != true
            else
            {
                return nil
            }
            let folder = values.isDirectory == true
            guard folder || ["md", "markdown"].contains(child.pathExtension.lowercased())
            else
            {
                return nil
            }
            return FolderEntry(url: child, isFolder: folder)
        }
        .sorted
        { lhs, rhs in
            if lhs.isFolder != rhs.isFolder
            {
                return lhs.isFolder
            }
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }
}
