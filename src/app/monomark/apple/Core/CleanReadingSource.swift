// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 70b6a3d1-23f7-42b6-8138-dca4e0580016
// COMPONENT: Source-line translation
// PURPOSE: Translate references after removing generated sections without allocating a map for every source line.
struct CleanReadingSource
{
    let text: String
    let sections: [GeneratedReadingSection]

    func translatedLine(_ line: Int) -> Int?
    {
        var low = 0
        var high = sections.count
        while low < high
        {
            let middle = (low + high) / 2
            if sections[middle].lastLine < line
            {
                low = middle + 1
            }
            else
            {
                high = middle
            }
        }
        if low < sections.count
        {
            let section = sections[low]
            if line >= section.firstLine
            {
                return nil
            }
            return line - section.removedBefore
        }
        let last = sections.last
        return line - (last.map
        {
            $0.removedBefore + $0.removedBreaks
        } ?? 0)
    }

    func translating(_ notes: ReadingNotes) -> ReadingNotes
    {
        var result = notes
        result.annotations = notes.annotations.map
        { annotation in
            var copy = annotation
            copy.anchors = annotation.anchors.map
            { anchor in
                var copy = anchor
                if let location = anchor.location, let line = translatedLine(location.line),
                   let end = translatedLine(location.endLine)
                {
                    copy.location = SourceLocation(line: line, endLine: end, section: location.section)
                }
                else
                {
                    copy.location = nil
                }
                return copy
            }
            return copy
        }
        return result
    }
}
