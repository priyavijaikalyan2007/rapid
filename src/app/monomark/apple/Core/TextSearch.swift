// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 68ec811b-f84d-43ac-aef0-83e5da3fd30c
// COMPONENT: Local reading-note search
// PURPOSE: Produce bounded UTF-16 ranges for native text views without changing their contents.
import Foundation

enum TextSearch
{
    static func ranges(in text: String, query: String) -> [NSRange]
    {
        guard !query.isEmpty
        else
        {
            return []
        }
        let source = text as NSString
        var cursor = 0
        var result: [NSRange] = []
        while cursor < source.length && result.count < 10000
        {
            let match = source.range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: NSRange(location: cursor, length: source.length - cursor)
            )
            if match.location == NSNotFound || match.length == 0
            {
                break
            }
            result.append(match)
            cursor = NSMaxRange(match)
        }
        return result
    }
}
