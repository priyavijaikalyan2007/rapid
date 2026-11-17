// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 07758b38-4599-45dd-85bd-4164256c401a
// COMPONENT: Export source resolution
// PURPOSE: Resolve saved quotations against the loaded document before explicit export.
import Foundation
import WebKit

extension ReaderSession
{
    func readingNotesForExport() async throws -> ReadingNotes
    {
        guard let webView, url != nil, await annotations.drain()
        else
        {
            throw ReaderFailure.unavailable
        }
        let ticket = documentEpoch
        var notes = ReadingNotes(annotations: annotations.records, text: annotations.text, format: annotations.format)
        let payload = try JSONSerialization.jsonObject(with: JSONEncoder().encode(notes.annotations))
        let result = try await webView.callAsyncJavaScript(
            "return await window.MonoMark.exportLocations(records)",
            arguments: ["records": payload], in: nil, contentWorld: .page
        )
        guard ticket == documentEpoch, let object = result as? [String: Any],
              let resolved = object["annotations"], let hash = object["sourceHash"] as? String
        else
        {
            throw AnnotationFailure.sourceChanged
        }
        notes.annotations = try JSONDecoder().decode(
            [ReadingAnnotation].self, from: JSONSerialization.data(withJSONObject: resolved)
        )
        notes.sourceHash = hash
        return notes
    }
}
