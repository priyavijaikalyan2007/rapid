// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b49a91c3-7e13-4b03-b378-d2e2e73c1e23
// Created: 2026
// COMPONENT: MonoMark core
// PURPOSE: Resolve fragments, files, and external addresses through one policy.
// RELATES: MonoMarkCoreTests
// FLOW: Validated input -> local processing -> typed result.

import Foundation

/// Local links cannot expand the granted document or folder scope.
enum LinkPolicy
{
    static func resolve(_ raw: String, relativeTo source: URL, root: URL) -> LinkDestination
    {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.utf8.count < 16384
        else
        {
            return .denied
        }
        if text.hasPrefix("#")
        {
            return .fragment(String(text.dropFirst()).removingPercentEncoding ?? "")
        }
        guard let url = URL(string: text, relativeTo: source)?.absoluteURL
        else
        {
            return .denied
        }
        if let scheme = url.scheme?.lowercased(), ["https", "http", "mailto"].contains(scheme)
        {
            return .external(url)
        }
        guard url.isFileURL, DocumentAccess.contains(url, in: root)
        else
        {
            return .denied
        }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let fragment = components?.fragment
        components?.fragment = nil
        guard let file = components?.url
        else
        {
            return .denied
        }
        if ["md", "markdown"].contains(file.pathExtension.lowercased())
        {
            return .document(file, fragment)
        }
        return .file(file)
    }
}
