// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: ef7f7364-5404-4f3a-834e-ae8912f36032
// COMPONENT: Reader document bookmarks
// PURPOSE: Resolve native document grants without inferring authority from stored paths.
import Foundation

extension ReaderSession
{
    func bookmark(_ url: URL) -> Data?
    {
        #if os(macOS)
        try? url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        #else
        try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        #endif
    }

    func resolve(_ data: Data?) -> URL?
    {
        guard let data
        else
        {
            return nil
        }
        var stale = false
        #if os(macOS)
        return try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        )
        #else
        return try? URL(resolvingBookmarkData: data, relativeTo: nil, bookmarkDataIsStale: &stale)
        #endif
    }
}
