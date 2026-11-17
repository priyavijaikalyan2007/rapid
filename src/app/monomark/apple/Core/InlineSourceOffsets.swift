// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 70b6a3d1-23f7-42b6-8138-dca4e0580019
// COMPONENT: Export reference adjustment
// PURPOSE: Make inline references point to source lines in the final exported file.
struct InlineSourceOffsets
{
    private let placements: [InlineAnnotationPlacement]
    private let totals: [Int]

    init(_ placements: [InlineAnnotationPlacement])
    {
        self.placements = placements
        var totals = [0]
        var total = 0
        for placement in placements
        {
            total += placement.addedLines
            totals.append(total)
        }
        self.totals = totals
    }

    private func shifted(_ line: Int) -> Int
    {
        var low = 0
        var high = placements.count
        while low < high
        {
            let middle = (low + high) / 2
            if placements[middle].endLine < line
            {
                low = middle + 1
            }
            else
            {
                high = middle
            }
        }
        return line + totals[low]
    }

    func applying(to annotation: ReadingAnnotation) -> ReadingAnnotation
    {
        var result = annotation
        result.anchors = annotation.anchors.map
        { anchor in
            var copy = anchor
            if let location = anchor.location
            {
                copy.location = SourceLocation(
                    line: shifted(location.line),
                    endLine: shifted(location.endLine),
                    section: location.section
                )
            }
            return copy
        }
        return result
    }
}
