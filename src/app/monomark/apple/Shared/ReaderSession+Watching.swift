// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 7e3ad8c4-7b9e-4602-9671-07fbf7bdca59
// COMPONENT: Local document change observation
// PURPOSE: Release file observation when a document closes or changes.
// FLOW: Filesystem event -> current generation check -> reader refresh.

import Foundation

extension ReaderSession
{
    func watch(_ file: URL)
    {
        watcher?.cancel()
        hasExternalChanges = false
        let ticket = documentEpoch
        watcher = DocumentWatcher(file: file)
        { [weak self] in
            guard let self, self.documentEpoch == ticket
            else
            {
                return
            }
            hasExternalChanges = true
            if preferences.autoReload, FileManager.default.fileExists(atPath: file.path)
            {
                refresh(reindexReferences: false)
            }
            else
            {
                message = "The file changed outside MonoMark. Select Refresh to view the latest content."
            }
        }
    }

    /// Refresh rendering without replacing the local annotation controller or changing the current tab.
    func refresh(reindexReferences: Bool = true)
    {
        guard url != nil
        else
        {
            return
        }
        hasExternalChanges = false
        if !rendererReady
        {
            if reindexReferences, let view = webView
            {
                (view.navigationDelegate as? WebCoordinator)?.retryReader(view)
            }
            return
        }
        if reindexReferences, preferences.implicitFileLinks
        {
            reparseReferences(force: true)
        }
        else
        {
            loadRenderer()
        }
    }
}
