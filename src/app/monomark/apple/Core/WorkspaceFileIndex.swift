// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 7b00d813-2124-4f75-a7ad-85e4ac099cd2
// COMPONENT: Optional workspace reference index
// PURPOSE: Read bounded Markdown paths without reading sibling document contents.
import Foundation

struct WorkspaceFileIndex: Sendable
{
    let root: URL
    let paths: [String]
    var truncated = false

    func relativePath(for file: URL) -> String?
    {
        let parent = root.resolvingSymlinksInPath().standardizedFileURL.path + "/"
        let path = file.resolvingSymlinksInPath().standardizedFileURL.path
        guard path.hasPrefix(parent)
        else
        {
            return nil
        }
        return String(path.dropFirst(parent.count))
    }

    static func scan(_ folder: URL, entryLimit: Int = 100000, fileLimit: Int = 10000) throws -> Self
    {
        let root = folder.resolvingSymlinksInPath().standardizedFileURL
        guard try root.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true
        else
        {
            return Self(root: root, paths: [])
        }
        guard let entries = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [
                .isRegularFileKey,
                .isSymbolicLinkKey
            ],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in
                true
            }
        ) else
        {
            throw ReaderFailure.denied
        }
        var result = Self(root: root, paths: [])
        var paths: [String] = []
        var count = 0
        for case let file as URL in entries
        {
            try Task.checkCancellation()
            count += 1
            if count > max(1, min(entryLimit, 100000)) || paths.count >= max(1, min(fileLimit, 10000))
            {
                result.truncated = true
                break
            }
            guard let values = try? file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            else
            {
                continue
            }
            // DirectoryEnumerator does not follow symlinks. Calling skipDescendants on a link can skip a sibling.
            if values.isSymbolicLink == true
            {
                continue
            }
            guard values.isRegularFile == true, ["md", "markdown"].contains(file.pathExtension.lowercased()),
                  let path = result.relativePath(for: file), path.utf8.count <= 4096
            else
            {
                continue
            }
            paths.append(path)
        }
        return Self(root: root, paths: paths.sorted(), truncated: result.truncated)
    }
}
