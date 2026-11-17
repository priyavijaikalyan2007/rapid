// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 70b6a3d1-23f7-42b6-8138-dca4e0580021
// COMPONENT: Selective reading-data export
// PURPOSE: Keep content and placement choices independent of local autosave.
struct ReadingExportOptions: Equatable, Sendable
{
    var includeAnnotations = true
    var includeNotes = true
    var layout = ReadingExportLayout.endSection
    var dataOnly = false

    func selected(_ notes: ReadingNotes) -> ReadingNotes
    {
        var result = notes
        if !includeAnnotations
        {
            result.annotations = []
        }
        if !includeNotes
        {
            result.text = ""
        }
        return result
    }

    func render(source: String, notes: ReadingNotes) throws -> String
    {
        guard includeAnnotations || includeNotes
        else
        {
            throw AnnotationFailure.invalidData
        }
        let notes = selected(notes)
        if let expected = notes.sourceHash, (!dataOnly || !notes.annotations.isEmpty),
           expected != DocumentStamp.make(source)
        {
            throw AnnotationFailure.sourceChanged
        }
        if dataOnly
        {
            return try AnnotationExporter.render(source: "", notes: notes)
        }
        if layout == .inline
        {
            return try InlineAnnotationExporter.render(source: source, notes: notes)
        }
        let clean = try GeneratedReadingSections.clean(source, includeFooter: false)
        return try AnnotationExporter.render(source: clean.text, notes: clean.translating(notes))
    }
}
