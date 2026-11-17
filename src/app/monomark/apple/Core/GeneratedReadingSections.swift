// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 70b6a3d1-23f7-42b6-8138-dca4e0580017
// COMPONENT: Generated-section replacement
// PURPOSE: Preserve every unowned source byte while removing prior app-generated output.
import Foundation

enum GeneratedReadingSections
{
    static func clean(_ source: String, includeFooter: Bool = true) throws -> CleanReadingSource
    {
        var scanner = GeneratedReadingSectionScanner()
        var line = 0
        var failure: Error?
        source.enumerateSubstrings(in: source.startIndex ..< source.endIndex, options: .byLines)
        { text, _, range, stop in
            line += 1
            do
            {
                try scanner.consume(text ?? "", range: range, line: line)
            }
            catch
            {
                failure = error
                stop = true
            }
        }
        if let failure
        {
            throw failure
        }
        try scanner.finish()
        var sections = scanner.sections.filter
        {
            includeFooter || $0.id != "footer"
        }
        adjustJoins(source, sections: &sections)
        var output = ""
        output.reserveCapacity(source.utf8.count)
        var cursor = source.startIndex
        for section in sections
        {
            output += source[cursor ..< section.range.lowerBound]
            cursor = section.range.upperBound
        }
        output += source[cursor...]
        return CleanReadingSource(text: output, sections: sections)
    }

    private static func adjustJoins(_ source: String, sections: inout [GeneratedReadingSection])
    {
        var cursor = source.endIndex
        var unownedSuffix = false
        for index in sections.indices.reversed()
        {
            unownedSuffix = unownedSuffix || sections[index].range.upperBound != cursor
            let start = sections[index].range.lowerBound
            if sections[index].joinsPreviousLine, !unownedSuffix, start > source.startIndex
            {
                let previous = source.index(before: start)
                if source[previous].isNewline
                {
                    sections[index].range = previous ..< sections[index].range.upperBound
                }
            }
            cursor = sections[index].range.lowerBound
        }
        var removed = 0
        for index in sections.indices
        {
            sections[index].removedBefore = removed
            let text = source[sections[index].range].replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
            sections[index].removedBreaks = text.filter
            {
                $0 == "\n"
            }.count
            removed += sections[index].removedBreaks
        }
    }
}
