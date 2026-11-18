// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 5b1256d7-e098-40e4-8cb5-3cd3b291433c
// COMPONENT: Reader review acceptance
// PURPOSE: Verify heading selection, table geometry, and typography in actual WebKit.
import AppKit
import WebKit

@MainActor enum ReviewSmoke
{
    static func createFixture() throws -> URL
    {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("monomark-review-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let source = """
            # Reader review

            **Status:** Draft
            **Date:** 16 November 2026

            Inline operators: `and`, `or`, `not`.

            ## 3. Three forms

            | Form | Reader | Location |
            | --- | --- | --- |
            | Text | A person who reads queries | The current document |
            | Tree | Code | A local file |

            ### Author-controlled subsection

            """
        let middle = (1 ... 150).map
        {
            "Paragraph \($0). A synthetic reading fixture.\n\n"
        }.joined()
        let file = folder.appendingPathComponent("Review.md")
        try Data((source + "\n\n" + middle + "## Far location\n\nEnd.\n").utf8).write(to: file)
        try Data("# Another tab\n\nIndependent document.\n".utf8)
            .write(to: folder.appendingPathComponent("Other.md"))
        return file
    }

    static func run(session: ReaderSession, output: String) async throws -> [String: Any]
    {
        guard let view = session.webView, let source = session.url
        else
        {
            throw ReaderFailure.unavailable
        }
        let original = try Data(contentsOf: source)
        session.preferences.fontFamily = "Atkinson Hyperlegible"
        session.preferences.showLineNumbers = true
        session.preferences.preserveLineBreaks = true
        session.updatePreferences()
        try await waitFor(
            """
            !!document.getElementById('3-three-forms') && !!document.querySelector('th') && \
            !!document.querySelector('.monomark-line-number')
            """,
            view: view
        )
        try await Task.sleep(for: .milliseconds(200))
        trace("initial geometry")
        let before = try await geometry(view)
        trace("heading selection")
        try await selectHeading(view)
        try await Task.sleep(for: .milliseconds(200))
        let captured = session.annotations.selection.count
        session.annotations.addSelection()
        guard let annotation = session.annotations.records.last, await session.annotations.drain()
        else
        {
            throw NSError(domain: "MonoMarkReview", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "The heading annotation was not created.",
                "capturedAnchors": captured, "notesReady": session.annotations.ready,
                "notesError": session.annotations.error ?? ""
            ])
        }
        trace("annotation navigation")
        session.command(["type": "jump", "id": "far-location"])
        try await waitFor("!!document.querySelector('#far-location')", view: view)
        session.command(["type": "annotation", "id": annotation.id])
        try await waitFor("!!document.querySelector('h2 mark') && !!document.querySelector('th')", view: view)
        var report = try await geometry(view)
        report["beforeJump"] = before
        report["headingQuote"] = annotation.anchors.map(\.quote).joined(separator: "\n")
        report["anchorCount"] = annotation.anchors.count
        report["sourceUnchanged"] = try Data(contentsOf: source) == original
        trace("annotation export")
        let notes = try await session.readingNotesForExport()
        let exported = try AnnotationExporter.render(source: String(decoding: original, as: UTF8.self), notes: notes)
        report["exportSourceHash"] = notes.sourceHash == DocumentStamp.make(String(decoding: original, as: UTF8.self))
        report["exportSectionAndLine"] = exported.contains("**Source lines:** 8") && exported.contains("Three forms")
        report["passed"] = checksPass(report, typography: false) && checksPass(before) && annotation.anchors
            .count == 1 &&
            annotation.anchors.first?.quote == "3. Three forms" && report["sourceUnchanged"] as? Bool == true
        report["passed"] = report["passed"] as? Bool == true && report["exportSourceHash"] as? Bool == true &&
            report["exportSectionAndLine"] as? Bool == true
        trace("inline export")
        let inline = try await ReviewExportSmoke.run(session: session, source: source, notes: notes)
        report["inlineAndSelectiveExports"] = inline
        report["passed"] = report["passed"] as? Bool == true && inline.values.allSatisfy
        {
            $0 as? Bool == true
        }
        trace("implicit links")
        let links = try await ReviewLinkSmoke.run(session: session)
        report["implicitLinks"] = links
        report["passed"] = report["passed"] as? Bool == true && links.values.allSatisfy
        {
            $0 as? Bool == true
        }
        trace("large selection")
        let selection = try await ReviewSelectionSmoke.run(session: session)
        report["longSelection"] = selection
        report["passed"] = report["passed"] as? Bool == true && selection.values.allSatisfy
        {
            $0
        }
        trace("table print")
        let tables = try await ReviewTableSmoke.run(session: session)
        report["largeTableAndPrint"] = tables
        report["passed"] = report["passed"] as? Bool == true && tables["passed"] as? Bool == true
        trace("quote recovery")
        let reattachment = try await ReviewReattachmentSmoke.run(session: session)
        report["externalEditReattachment"] = reattachment
        report["passed"] = report["passed"] as? Bool == true && reattachment.values.allSatisfy
        {
            $0
        }
        let image = try await view.takeSnapshot(configuration: nil)
        if let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:])
        {
            try png.write(to: URL(fileURLWithPath: output + ".png"))
        }
        return report
    }

    private static func trace(_ stage: String)
    {
        FileHandle.standardError.write(Data("MonoMark review: \(stage)\n".utf8))
    }

    private static func checksPass(_ report: [String: Any], typography: Bool = true) -> Bool
    {
        (typography ? [
            "columnsAligned",
            "uniqueIDs",
            "validTableMarks",
            "monospaceCode",
            "separatePreambleLines",
            "sourceGutter"
        ] :
            ["columnsAligned", "uniqueIDs", "validTableMarks", "sourceGutter", "headingMarked"])
            .allSatisfy
            {
                report[$0] as? Bool == true
            }
    }

    private static func waitFor(_ condition: String, view: WKWebView) async throws
    {
        for _ in 0 ..< 80
        {
            if try await view.evaluateJavaScript(condition) as? Bool == true
            {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw ReaderFailure.unavailable
    }

    private static func selectHeading(_ view: WKWebView) async throws
    {
        _ = try await view.evaluateJavaScript("""
            (() => {
                const range = document.createRange();
                range.setStart(document.getElementById('3-three-forms').firstChild, 0);
                range.setEnd(document.querySelector('thead'), 1);
                window.getSelection().removeAllRanges(); window.getSelection().addRange(range);
                document.dispatchEvent(new MouseEvent('mouseup', {bubbles:true}));
            })()
            """)
    }

    private static func geometry(_ view: WKWebView) async throws -> [String: Any]
    {
        let result = try await view.evaluateJavaScript("""
            (() => {
                const headers = [...document.querySelectorAll('thead th')].map(x => x.getBoundingClientRect());
                const cells = [...document.querySelectorAll('tbody tr:first-child td')].map(x => x.getBoundingClientRect());
                const ids = [...document.querySelectorAll('[id]')].map(x => x.id);
                const strong = [...document.querySelectorAll('p strong')];
                const code = document.querySelector('code');
                const font = code ? getComputedStyle(code).fontFamily : ''; 
                const label = document.querySelector('.monomark-line-number')?.textContent;
                return {
                    columnsAligned: headers.length === 3 && cells.length === 3 && headers.every((x,i) =>
                        Math.abs(x.left-cells[i].left) < 0.5 && Math.abs(x.width-cells[i].width) < 0.5),
                    columnLefts: headers.map(x => x.left), bodyLefts: cells.map(x => x.left),
                    uniqueIDs: new Set(ids).size === ids.length,
                    validTableMarks: !document.querySelector('table > mark, thead > mark, tbody > mark, tr > mark'),
                    monospaceCode: font.includes('monospace'), codeFont: font,
                    separatePreambleLines: strong.length >= 2 &&
                        strong[1].getBoundingClientRect().top > strong[0].getBoundingClientRect().top,
                    sourceGutter: /^\\d{3}$/.test(label || ''),
                    headingText: document.getElementById('3-three-forms')?.textContent,
                    headingMarked: !!document.getElementById('3-three-forms')?.querySelector('mark')
                };
            })()
            """)
        guard let report = result as? [String: Any]
        else
        {
            throw ReaderFailure.unavailable
        }
        return report
    }
}
