// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 87b7d779-401c-4e7b-823b-653881961b3f
// COMPONENT: Native highlight recovery acceptance
// PURPOSE: Verify external edits, offscreen ambiguity, and source references through the actual worker bridge.
import Foundation
import WebKit

@MainActor enum ReviewReattachmentSmoke
{
    static func run(session: ReaderSession) async throws -> [String: Bool]
    {
        let (file, view, annotation, changed) = try await prepareEditedFixture(session)
        let notes = try await session.readingNotesForExport()
        let location = notes.annotations.first?.anchors.first?.location
        let unique = location?.line == 1203 && location?.section.contains("Reattachment review") == true
        var report = ["reattachedBeyondViewport": unique, "exportUsesCurrentSectionAndLine": unique]
        report["ambiguousQuoteUnattached"] = try await verifyAmbiguity(
            session,
            view: view,
            file: file,
            source: changed,
            annotation: annotation
        )
        report["deletedQuoteUnattached"] = try await verifyDeletion(
            session,
            view: view,
            file: file,
            source: changed,
            annotation: annotation
        )
        report["savedAnchorPreserved"] = session.annotations.records.first?.anchors.first?.blockID == "block-1"
        report["boundedViewport"] = try await view
            .evaluateJavaScript("window.MonoMark.metrics().mounted<=80") as? Bool == true
        return report
    }

    private static func prepareEditedFixture(_ session: ReaderSession) async throws
        -> (URL, WKWebView, ReadingAnnotation, String)
    {
        let file = try fixture()
        session.open(file, folder: file.deletingLastPathComponent())
        guard let view = session.webView
        else
        {
            throw ReaderFailure.unavailable
        }
        try await waitDOM(
            view,
            "!!document.getElementById('reattachment-review') && !!document.querySelector('#block-1 p')"
        )
        session.preferences.autoReload = false
        let annotation = try await createAnnotation(session, view: view)
        let inserted = (0 ..< 600).map
        {
            "Inserted paragraph \($0).\n\n"
        }.joined()
        let changed = "# Reattachment review\n\n" + inserted + "Before chosen phrase after.\n\n## End\n\nDone.\n"
        try changed.write(to: file, atomically: true, encoding: .utf8)
        session.refresh(reindexReferences: false)
        try await waitDOM(view, "window.MonoMark.metrics().blocks===604")
        session.navigateAnnotation(annotation)
        try await waitDOM(view, "!!document.querySelector('#block-601 mark')")
        return (file, view, annotation, changed)
    }

    private static func fixture() throws -> URL
    {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("monomark-reattach-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("Reading.md")
        try "# Reattachment review\n\nBefore chosen phrase after.\n\n## End\n\nDone.\n"
            .write(to: file, atomically: false, encoding: .utf8)
        return file
    }

    private static func createAnnotation(_ session: ReaderSession, view: WKWebView) async throws -> ReadingAnnotation
    {
        try await wait
        {
            session.annotations.ready
        }
        _ = try await view.evaluateJavaScript("""
            (()=>{
                const range=document.createRange();
                range.selectNodeContents(document.querySelector('#block-1 p'));
                window.getSelection().removeAllRanges();window.getSelection().addRange(range);
                document.dispatchEvent(new MouseEvent('mouseup',{bubbles:true}));
            })()
            """)
        try await wait
        {
            session.annotations.selection.count == 1
        }
        session.annotations.addSelection()
        guard await session.annotations.drain(), let annotation = session.annotations.records.first
        else
        {
            throw ReaderFailure.unavailable
        }
        return annotation
    }

    private static func verifyAmbiguity(
        _ session: ReaderSession,
        view: WKWebView,
        file: URL,
        source: String,
        annotation: ReadingAnnotation
    ) async throws -> Bool
    {
        let duplicate = source + "\nBefore chosen phrase after.\n"
        try duplicate.write(to: file, atomically: true, encoding: .utf8)
        session.refresh(reindexReferences: false)
        try await waitDOM(view, "window.MonoMark.metrics().blocks===605")
        session.navigateAnnotation(annotation)
        try await wait
        {
            session.message.contains("more than one matching location")
        }
        let notes = try await session.readingNotesForExport()
        let unchanged = try String(contentsOf: file, encoding: .utf8) == duplicate
        let noMark = try await view.evaluateJavaScript("document.querySelector('mark')===null") as? Bool == true
        return notes.annotations.first?.anchors.first?.location == nil && unchanged && noMark
    }

    private static func verifyDeletion(
        _ session: ReaderSession,
        view: WKWebView,
        file: URL,
        source: String,
        annotation: ReadingAnnotation
    ) async throws -> Bool
    {
        let deleted = source.replacingOccurrences(of: "Before chosen phrase after.\n\n", with: "")
        try deleted.write(to: file, atomically: true, encoding: .utf8)
        session.refresh(reindexReferences: false)
        try await waitDOM(view, "window.MonoMark.metrics().blocks===603")
        session.navigateAnnotation(annotation)
        try await wait
        {
            session.message.contains("no longer matches")
        }
        let notes = try await session.readingNotesForExport()
        let unchanged = try String(contentsOf: file, encoding: .utf8) == deleted
        return notes.annotations.first?.anchors.first?.location == nil && unchanged
    }

    private static func wait(_ condition: () -> Bool) async throws
    {
        for _ in 0 ..< 150
        {
            if condition()
            {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw ReaderFailure.unavailable
    }

    private static func waitDOM(_ view: WKWebView, _ condition: String) async throws
    {
        for _ in 0 ..< 150
        {
            if try await view.evaluateJavaScript(condition) as? Bool == true
            {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw ReaderFailure.unavailable
    }
}
