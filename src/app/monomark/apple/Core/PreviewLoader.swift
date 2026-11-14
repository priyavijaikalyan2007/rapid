// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f65d3bb2-32ec-4adc-ac23-4eb252f86125
// Created: 2026
// COMPONENT: MonoMark core
// PURPOSE: Produce a bounded local preamble without rendering or navigation side effects.
// RELATES: MonoMarkCoreTests
// FLOW: Validated input -> local processing -> typed result.

import Foundation

/// Local excerpts never create history records or execute Markdown objects.
enum PreviewLoader
{
    static func load(_ file: URL, root: URL) throws -> String
    {
        guard DocumentAccess.contains(file, in: root)
        else
        {
            throw ReaderFailure.denied
        }
        var text = try DocumentAccess.prefix(file)
        if text.hasPrefix("---\n"), let end = text.range(
            of: "\n---",
            range: text.index(text.startIndex, offsetBy: 4) ..< text.endIndex
        )
        {
            text = String(text[end.upperBound...])
        }
        var fenced = false
        let prose = text.split(separator: "\n").compactMap
        { line -> String? in
            if line.hasPrefix("```") || line.hasPrefix("~~~")
            {
                fenced.toggle()
                return nil
            }
            if fenced || line.hasPrefix("![")
            {
                return nil
            }
            return line.trimmingCharacters(in: CharacterSet(charactersIn: "#> *-\t\r"))
        }.joined(separator: " ")
        return String(prose.prefix(600))
    }
}
