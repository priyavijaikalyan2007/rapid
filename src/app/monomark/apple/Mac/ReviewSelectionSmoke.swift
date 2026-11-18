// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 2a0e89ef-9b8c-47ef-ab19-cde6554733ad
// COMPONENT: Native long-selection acceptance
// PURPOSE: Verify unloaded selection, annotations, and full-index clipboard text in actual WebKit.
import Foundation
import WebKit

@MainActor enum ReviewSelectionSmoke
{
    static func run(session: ReaderSession) async throws -> [String: Bool]
    {
        let (source, paragraphs) = try fixture()
        session.open(source, folder: source.deletingLastPathComponent())
        guard let view = session.webView
        else
        {
            throw ReaderFailure.unavailable
        }
        try await waitDOM(
            view,
            "!!document.getElementById('large-selection') && window.MonoMark.metrics().blocks === 1501"
        )
        try await selectAcrossViewport(view)
        try await wait
        {
            session.annotations.selection.count == 60
        }
        let anchors = session.annotations.selection
        let partial = [String(paragraphs[0].dropFirst(10))] + Array(paragraphs[1 ..< 59]) +
            [String(paragraphs[59].prefix(24))]
        let partialCopy = try await verifyCopy(session, view, expected: partial.joined(separator: "\n\n"))
        let full = (["Large selection"] + paragraphs).joined(separator: "\n\n")
        _ = try await view.evaluateJavaScript("""
            document.getElementById('monomark-document').dispatchEvent(new KeyboardEvent('keydown',
                {key:'a',metaKey:true,bubbles:true,cancelable:true}));
            """)
        let fullCopy = try await verifyCopy(session, view, expected: full)
        let limited = try await view.evaluateJavaScript("window.MonoMark.metrics().mounted <= 80") as? Bool == true
        return [
            "unloadedAnchors": anchors.first?.blockID == "block-1" && anchors.last?.blockID == "block-60",
            "partialCopy": partialCopy,
            "fullDocumentCopy": fullCopy,
            "copyBeyondFourMiB": full.utf8.count > 4 * 1024 * 1024,
            "boundedViewport": limited,
            "sourceUnchanged": try String(contentsOf: source, encoding: .utf8) == "# " + full + "\n"
        ]
    }

    private static func fixture() throws -> (URL, [String])
    {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("monomark-selection-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let paragraphs = (1 ... 1500).map
        {
            "Paragraph \($0). " + String(repeating: "Reading text stays local. ", count: 120)
                .trimmingCharacters(in: .whitespaces)
        }
        let source = folder.appendingPathComponent("Selection.md")
        try ("# Large selection\n\n" + paragraphs.joined(separator: "\n\n") + "\n")
            .write(to: source, atomically: false, encoding: .utf8)
        return (source, paragraphs)
    }

    private static func selectAcrossViewport(_ view: WKWebView) async throws
    {
        _ = try await view.evaluateJavaScript("""
            (() => {
                const a=document.getElementById('block-1').querySelector('p').firstChild;
                const b=document.getElementById('block-2').querySelector('p').firstChild;
                window.getSelection().setBaseAndExtent(a,10,b,20);
                document.dispatchEvent(new MouseEvent('mouseup',{bubbles:true}));
                window.MonoMark.command({type:'jump',id:'block-60'});
            })()
            """)
        try await waitDOM(view, "!!document.getElementById('block-60') && !document.getElementById('block-1')")
        _ = try await view.evaluateJavaScript("""
            (() => {
                const root=document.getElementById('monomark-document');
                root.dispatchEvent(new KeyboardEvent('keydown',{key:'Shift',shiftKey:true,bubbles:true}));
                const a=root.querySelector('.monomark-block p').firstChild;
                const b=document.getElementById('block-60').querySelector('p').firstChild;
                window.getSelection().setBaseAndExtent(a,0,b,24);
                document.dispatchEvent(new MouseEvent('mouseup',{bubbles:true}));
            })()
            """)
    }

    private static func verifyCopy(_ session: ReaderSession, _ view: WKWebView, expected: String) async throws -> Bool
    {
        session.lastCopyRequest = [:]
        _ = try await view.evaluateJavaScript("""
            document.getElementById('monomark-document').dispatchEvent(new Event('copy',
                {bubbles:true,cancelable:true}));
            """)
        try await wait
        {
            session.lastCopyRequest["textPasteboardVerified"] as? Bool == true
        }
        return session.lastCopyRequest["textHash"] as? String == DocumentStamp.make(expected) &&
            session.lastCopyRequest["textBytes"] as? Int == expected.utf8.count
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
