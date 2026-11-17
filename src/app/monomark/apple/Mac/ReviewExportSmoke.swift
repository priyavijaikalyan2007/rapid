// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 12c193b3-7758-47ea-a972-9d25260d3833
// COMPONENT: Native export acceptance
// PURPOSE: Verify actual renderer locations through copy, inline replacement, and selective sidecar output.
import Foundation
import WebKit

@MainActor enum ReviewExportSmoke
{
    static func run(session: ReaderSession, source: URL, notes: ReadingNotes) async throws -> [String: Any]
    {
        let original = try Data(contentsOf: source)
        let copy = source.deletingLastPathComponent().appendingPathComponent("Inline copy.md")
        var selected = notes
        selected.text = "A native export note."
        if !selected.annotations
            .isEmpty
        {
            selected.annotations[0].comment = "A comment about the highlighted heading."
        }
        let options = ReadingExportOptions(layout: .inline)
        try AnnotationExportWriter.write(source: source, destination: copy, notes: selected, options: options)
        let first = try String(contentsOf: copy, encoding: .utf8)
        let clean = try GeneratedReadingSections.clean(first).text
        let originalPreserved = Data(clean.utf8) == original
        session.open(copy, folder: copy.deletingLastPathComponent())
        try await waitForDocument(copy, session: session)
        guard let annotation = selected.annotations.first
        else
        {
            throw ReaderFailure.unavailable
        }
        session.annotations.update(annotation)
        session.annotations.editNotes(selected.text)
        guard await session.annotations.drain()
        else
        {
            throw ReaderFailure.unavailable
        }
        let resolved = try await session.readingNotesForExport()
        try AnnotationExportWriter.write(source: copy, destination: copy, notes: resolved, options: options)
        let repeated = try String(contentsOf: copy, encoding: .utf8)
        let sidecar = copy.deletingLastPathComponent().appendingPathComponent("Notes only.md")
        try AnnotationExportWriter.write(
            source: copy,
            destination: sidecar,
            notes: resolved,
            options: ReadingExportOptions(includeAnnotations: false, dataOnly: true)
        )
        let sidecarText = try String(contentsOf: sidecar, encoding: .utf8)
        let oneHighlight = try await session.webView?.evaluateJavaScript(
            """
            document.querySelectorAll('mark[data-annotation]').length === 1 && \
            !document.querySelector('[data-generated=true] mark')
            """
        ) as? Bool == true
        let unchanged = try Data(contentsOf: source) == original
        return [
            "sourcePreserved": originalPreserved && unchanged,
            "repeatInlineExportStable": first == repeated,
            "onlyOriginalHighlighted": oneHighlight,
            "notesOnlySidecar": sidecarText.contains("A native export note.") && !sidecarText
                .contains("### Annotation"),
            "inlineComment": first.contains("**Comment:**\n\nA comment about the highlighted heading\\.")
        ]
    }

    private static func waitForDocument(_ file: URL, session: ReaderSession) async throws
    {
        for _ in 0 ..< 80
        {
            if session.url == file.resolvingSymlinksInPath(), !session.isLoading, session.annotations.ready
            {
                return
            }
            if session.url == file, !session.isLoading, session.annotations.ready
            {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw ReaderFailure.unavailable
    }
}
