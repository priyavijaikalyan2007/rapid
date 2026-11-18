// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 9e468fe4-3cbb-4c83-b970-d4e73e9399c3
// COMPONENT: Optional document-reference preparation
// PURPOSE: Share bounded workspace metadata and reparse only when reference choices change.
import Foundation

extension ReaderSession
{
    func prepareImplicitReferences(force: Bool = false) async
    {
        guard preferences.implicitFileLinks, let folder = root, let file = url, folder != file
        else
        {
            referenceIndex = nil
            referenceIndexTruncated = false
            return
        }
        let ticket = documentEpoch
        do
        {
            let index = try await WorkspaceFileIndexCache.shared.value(for: folder, force: force)
            guard ticket == documentEpoch, preferences.implicitFileLinks, !Task.isCancelled
            else
            {
                return
            }
            referenceIndex = index
            referenceIndexTruncated = index.truncated
        }
        catch
        {
            guard ticket == documentEpoch, !Task.isCancelled
            else
            {
                return
            }
            referenceIndex = nil
            referenceIndexTruncated = false
            message = "The optional file-reference index is unavailable. Refresh or reopen the folder to retry."
        }
    }

    func reparseReferences(force: Bool = false)
    {
        referenceTask?.cancel()
        let ticket = documentEpoch
        referenceTask = Task
        { [weak self] in
            guard let self
            else
            {
                return
            }
            await prepareImplicitReferences(force: force)
            guard !Task.isCancelled, ticket == documentEpoch
            else
            {
                return
            }
            loadRenderer()
        }
    }
}
