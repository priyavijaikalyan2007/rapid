// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 70b6a3d1-23f7-42b6-8138-dca4e0580015
// COMPONENT: Generated-section scanning
// PURPOSE: Reject nested, incomplete, or repeated ownership markers before any write.
struct GeneratedReadingSectionScanner
{
    var sections: [GeneratedReadingSection] = []
    private var fence = MarkdownFence()
    private var active: ReadingDataMarker?
    private var first: String.Index?
    private var firstLine = 0
    private var seen: Set<String> = []

    mutating func consume(_ text: String, range: Range<String.Index>, line: Int) throws
    {
        guard !fence.consume(text), let marker = try ReadingDataMarker.parse(text)
        else
        {
            return
        }
        if marker.starts
        {
            guard active == nil, seen.insert(marker.id).inserted
            else
            {
                throw AnnotationFailure.invalidMarkers
            }
            active = marker
            first = range.lowerBound
            firstLine = line
            return
        }
        guard let active, active.id == marker.id, let first
        else
        {
            throw AnnotationFailure.invalidMarkers
        }
        sections.append(GeneratedReadingSection(
            id: marker.id,
            range: first ..< range.upperBound,
            firstLine: firstLine,
            lastLine: line,
            joinsPreviousLine: active.joinsPreviousLine
        ))
        self.active = nil
        self.first = nil
    }

    func finish() throws
    {
        guard active == nil, !fence.isOpen
        else
        {
            throw AnnotationFailure.invalidMarkers
        }
    }
}
