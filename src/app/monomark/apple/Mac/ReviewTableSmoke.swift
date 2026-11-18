// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: e2ab31a2-1df0-4cde-952f-4346749dbef2
// COMPONENT: Native table and print acceptance
// PURPOSE: Verify bounded table layout, complete clipboard data, and actual paginated PDF output.
import AppKit
import PDFKit
import WebKit

@MainActor enum ReviewTableSmoke
{
    static func run(session: ReaderSession) async throws -> [String: Any]
    {
        let (source, original, csv) = try fixture(rows: 20000)
        session.open(source, folder: source.deletingLastPathComponent())
        guard let view = session.webView
        else
        {
            throw ReaderFailure.unavailable
        }
        try await waitDOM(view, "!!document.querySelector('table[data-table-key]')")
        session.command(["type": "find", "query": "Value 19999"])
        try await waitDOM(view, "[...document.querySelectorAll('td')].some(x=>x.textContent==='Value 19999')")
        var report = try await geometry(view)
        report["completeGridCopy"] = try await copyGrid(session, view: view, expected: csv)
        report["sourceUnchanged"] = try String(contentsOf: source, encoding: .utf8) == original
        report["rows"] = 20000
        report["print"] = try await printPDF(session)
        let printReport = report["print"] as? [String: Any] ?? [:]
        report["passed"] = [
            "boundedRows",
            "columnsAligned",
            "consistentWidths",
            "uniqueIDs",
            "completeGridCopy",
            "sourceUnchanged"
        ]
        .allSatisfy
        {
            report[$0] as? Bool == true
        } && printReport["passed"] as? Bool == true
        return report
    }

    private static func copyGrid(_ session: ReaderSession, view: WKWebView, expected: String) async throws -> Bool
    {
        session.lastCopyRequest = [:]
        _ = try await view.evaluateJavaScript("document.querySelector('[title=\"Copy entire table as CSV\"]').click()")
        try await wait
        {
            session.lastCopyRequest["textPasteboardVerified"] as? Bool == true
        }
        return session.lastCopyRequest["textHash"] as? String == DocumentStamp.make(expected)
    }

    private static func fixture(rows: Int) throws -> (URL, String, String)
    {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("monomark-table-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let values = (0 ..< rows).map
        {
            "\($0),Value \($0)"
        }
        let source = "# Table review\n\n| Index | Value |\n|---|---|\n" +
            values.map
            {
                "| " + $0.replacingOccurrences(of: ",", with: " | ") + " |"
            }.joined(separator: "\n") +
            "\n\n## After table\n\nPrint complete.\n"
        let file = folder.appendingPathComponent("Table.md")
        try source.write(to: file, atomically: false, encoding: .utf8)
        return (file, source, (["Index,Value"] + values).joined(separator: "\n"))
    }

    private static func geometry(_ view: WKWebView) async throws -> [String: Any]
    {
        let result = try await view.evaluateJavaScript("""
            (()=>{
                const tables=[...document.querySelectorAll('table[data-table-key]')];
                const widths=tables.map(t=>[...t.querySelectorAll('th')].map(x=>x.getBoundingClientRect().width));
                const aligned=tables.every(t=>[...t.querySelectorAll('th')].every((h,i)=>{
                    const cell=t.querySelectorAll('tbody tr:first-child td')[i];
                    return cell && Math.abs(h.getBoundingClientRect().left-cell.getBoundingClientRect().left)<0.5;
                }));
                const ids=[...document.querySelectorAll('[id]')].map(x=>x.id);
                return { boundedRows:document.querySelectorAll('tbody tr').length<=5120,
                    mountedRows:document.querySelectorAll('tbody tr').length,
                    columnsAligned:aligned, consistentWidths:widths.every(w=>w.every((n,i)=>Math.abs(n-widths[0][i])<0.5)),
                    uniqueIDs:new Set(ids).size===ids.length };
            })()
            """)
        guard let report = result as? [String: Any]
        else
        {
            throw ReaderFailure.unavailable
        }
        return report
    }

    private static func printPDF(_ session: ReaderSession) async throws -> [String: Any]
    {
        let (source, original, _) = try fixture(rows: 240)
        session.open(source, folder: source.deletingLastPathComponent())
        guard let view = session.webView
        else
        {
            throw ReaderFailure.unavailable
        }
        try await waitDOM(
            view,
            "!!document.querySelector('table[data-table-key]') && window.MonoMark.metrics().blocks<10"
        )
        session.command(["type": "jump", "id": "after-table"])
        try await waitDOM(view, "!!document.getElementById('after-table')")
        let oldAction = session.printAction
        defer { session.printAction = oldAction }
        var ready = false
        session.printAction = {
            ready = true
        }
        session.command(["type": "print"])
        try await wait
        {
            ready
        }
        let output = source.deletingLastPathComponent().appendingPathComponent("Table.pdf")
        let printed = try await savePDF(view, output: output)
        session.command(["type": "afterPrint"])
        try await waitDOM(view, "!!document.getElementById('after-table') && window.MonoMark.metrics().mounted<=80")
        return try pdfReport(output, printed: printed, source: source, original: original)
    }

    private static func pdfReport(_ output: URL, printed: Bool, source: URL, original: String) throws -> [String: Any]
    {
        let pdf = PDFDocument(url: output)
        let text = pdf?.string ?? ""
        let complete = (0 ..< 240).allSatisfy
        {
            text.range(of: "Value \($0)(?![0-9])", options: .regularExpression) != nil
        }
        return [
            "passed": printed && complete && (pdf?.pageCount ?? 0) > 1,
            "allRowsPresent": complete,
            "pages": pdf?.pageCount ?? 0,
            "restoredDocument": true,
            "sourceUnchanged": try String(contentsOf: source, encoding: .utf8) == original
        ]
    }

    private static func savePDF(_ view: WKWebView, output: URL) async throws -> Bool
    {
        let info = NSPrintInfo()
        info.paperSize = NSSize(width: 612, height: 792)
        info.topMargin = 36
        info.bottomMargin = 36
        info.leftMargin = 36
        info.rightMargin = 36
        info.jobDisposition = .save
        info.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = output
        let operation = view.printOperation(with: info)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false
        guard let window = view.window
        else
        {
            throw ReaderFailure.unavailable
        }
        let job = ReaderPrintJob(operation: operation) { _ in }
        job.start(window: window)
        try await wait
        {
            job.result != nil
        }
        return job.result == true
    }

    private static func wait(_ condition: () -> Bool) async throws
    {
        for _ in 0 ..< 300
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
        for _ in 0 ..< 300
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
