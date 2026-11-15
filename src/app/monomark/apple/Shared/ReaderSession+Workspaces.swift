// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: a5a1a7a3-a27a-4442-8e91-d74dd162e812
// COMPONENT: Native workspace navigation
// PURPOSE: Switch granted folders after notes save, resume their last document, and clear empty workspaces safely.
import Foundation

extension ReaderSession
{
    func retainScope(_ location: URL)
    {
        guard !scopes.contains(location), location.startAccessingSecurityScopedResource()
        else
        {
            return
        }
        scopes.append(location)
    }

    @discardableResult func loadFolder(_ folder: URL) async -> Bool
    {
        let ticket = documentEpoch
        retainScope(folder)
        do
        {
            let nodes = try await Task.detached
            {
                try FolderEntry.children(of: folder)
            }.value
            guard ticket == documentEpoch
            else
            {
                return false
            }
            root = folder
            entries = nodes
            return true
        }
        catch
        {
            fail(error)
            return false
        }
    }

    func switchWorkspace(_ record: WorkspaceRecord)
    {
        let folder = resolve(record.bookmark) ?? record.folder
        openWorkspace(folder, previous: record)
    }

    func openWorkspace(_ folder: URL, previous: WorkspaceRecord? = nil)
    {
        checkpoint()
        let previousGeneration = generation
        generation = UUID()
        let ticket = documentEpoch
        Task
        {
            var completed = false
            defer
            {
                if !completed && ticket == documentEpoch
                {
                    generation = previousGeneration
                }
            }
            guard await annotations.drain()
            else
            {
                message = annotations.error ?? "The reading notes could not be saved."
                return
            }
            guard ticket == documentEpoch, await loadFolder(folder), ticket == documentEpoch
            else
            {
                return
            }
            section = "Files"
            showSidebar = true
            let saved = previous ?? workspaces.records.first
            {
                $0.id == WorkspaceRecord(folder: folder).id
            }
            let resumed = saved?.resume(in: folder, resolvedFile: resolve(saved?.lastDocument?.bookmark))
            if let file = resumed.map({
                URL(fileURLWithPath: $0.path)
            }) ?? entries.first(where: {
                !$0.isFolder
            })?.url
            {
                completed = true
                open(file, folder: folder, resume: resumed)
            }
            else
            {
                completed = true
                clearForWorkspace(folder)
            }
        }
    }

    func releaseUnusedScopes(keeping locations: [URL])
    {
        let unused = scopes.filter
        {
            !locations.contains($0)
        }
        scopes.removeAll
        {
            !locations.contains($0)
        }
        for location in unused
        {
            location.stopAccessingSecurityScopedResource()
        }
    }

    func rememberWorkspace()
    {
        guard let root, let url, root != url, DocumentAccess.contains(url, in: root)
        else
        {
            return
        }
        let record = WorkspaceRecord(folder: root, bookmark: bookmark(root), document: state)
        Task
        {
            await workspaces.remember(record)
        }
    }

    private func clearForWorkspace(_ folder: URL)
    {
        releaseUnusedScopes(keeping: [folder])
        state = nil
        url = nil
        outline = []
        links = []
        isLoading = false
        currentPage = 1
        totalPages = 1
        watcher?.cancel()
        watcher = nil
        annotations.detach()
        titleChanged?(folder.lastPathComponent)
        command(["type": "clear", "epoch": documentEpoch])
        message = "Choose a Markdown file in this workspace."
        let record = WorkspaceRecord(folder: folder, bookmark: bookmark(folder))
        Task
        {
            await workspaces.remember(record)
        }
    }
}
