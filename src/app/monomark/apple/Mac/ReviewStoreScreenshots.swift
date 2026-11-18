// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: a206cd9c-6efe-4d6c-86eb-26a95c2d7ba6
// COMPONENT: Synthetic store screenshots
// PURPOSE: Capture actual app UI with public fixtures and app-local reading data.
import AppKit
import WebKit

@MainActor enum ReviewStoreScreenshots
{
    static func initialFile() throws -> URL
    {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "--screenshots-input"), args.indices.contains(index + 1)
        else
        {
            throw ReaderFailure.unavailable
        }
        let input = URL(fileURLWithPath: args[index + 1], isDirectory: true)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("MonoMark Examples")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for name in ["Welcome.md", "Guide.md"]
        {
            let bytes = try DocumentAccess.boundedRead(input.appendingPathComponent(name), limit: 64 * 1024)
            try bytes.write(to: root.appendingPathComponent(name))
        }
        return root.appendingPathComponent("Welcome.md")
    }

    static func run(application: AppDelegate, output: String) async throws -> [String: Any]
    {
        guard let controller = application.current, let source = controller.session.url,
              let view = controller.session.webView
        else
        {
            throw ReaderFailure.unavailable
        }
        let original = try Data(contentsOf: source)
        let mode = UserDefaults.standard.string(forKey: "appearance-mode")
        defer { UserDefaults.standard.set(mode, forKey: "appearance-mode") }
        configure(controller)
        let files = try await captures(controller, view: view, output: output)
        let unchanged = try Data(contentsOf: source) == original
        return [
            "passed": unchanged && files.count == 4,
            "sourceUnchanged": unchanged,
            "files": files,
            "width": 2560,
            "height": 1600,
            "alpha": false,
            "capture": "Actual compositor images of this process's own window. Synthetic fixtures only."
        ]
    }

    private static func configure(_ controller: ReaderWindowController)
    {
        controller.window?.setFrame(NSRect(x: 100, y: 100, width: 1280, height: 800), display: true)
        controller.session.preferences = ReaderPreferences()
        controller.session.updatePreferences()
        controller.session.section = "Files"
        controller.session.annotations.shown = false
    }

    private static func captures(
        _ controller: ReaderWindowController,
        view: WKWebView,
        output: String
    ) async throws -> [String]
    {
        var files: [String] = []
        files.append(try await capture(controller, view: view, mode: "light", output: output + ".01-reader.png"))
        try await jump(controller.session, view: view, heading: "3-equations-and-diagrams")
        try await waitDOM(view, "!!document.querySelector('.katex') && !!document.querySelector('[data-mermaid] svg')")
        files.append(try await capture(controller, view: view, mode: "dark", output: output + ".02-rich-dark.png"))
        try await annotation(controller.session, view: view)
        files.append(try await capture(controller, view: view, mode: "light", output: output + ".03-comments.png"))
        try await notes(controller.session, view: view)
        files.append(try await capture(controller, view: view, mode: "light", output: output + ".04-notes.png"))
        return files
    }

    private static func capture(
        _ controller: ReaderWindowController,
        view: WKWebView,
        mode: String,
        output: String
    ) async throws -> String
    {
        UserDefaults.standard.set(mode, forKey: "appearance-mode")
        try await waitDOM(view, "document.documentElement.style.colorScheme==='\(mode)'")
        try await Task.sleep(for: .milliseconds(700))
        guard let window = controller.window
        else
        {
            throw ReaderFailure.unavailable
        }
        let bitmap = try await ReviewWindowCapture.write(window, output: output)
        guard !bitmap.hasAlpha, bitmap.pixelsWide == 2560, bitmap.pixelsHigh == 1600
        else
        {
            throw ReaderFailure.unavailable
        }
        return URL(fileURLWithPath: output).lastPathComponent
    }

    private static func annotation(_ session: ReaderSession, view: WKWebView) async throws
    {
        try await jump(session, view: view, heading: "4-highlights-and-notes")
        try await selectQuote(session, view: view)
        session.annotations.addSelection()
        guard var note = session.annotations.records.first
        else
        {
            throw ReaderFailure.unavailable
        }
        note.comment = "Keep the key point beside the document. Export only when ready."
        session.annotations.update(note)
        session.annotations.shown = true
        session.section = "Contents"
        guard await session.annotations.drain()
        else
        {
            throw ReaderFailure.unavailable
        }
        try await waitDOM(view, "!!document.querySelector('mark[data-annotation]')")
        _ = try await view
            .evaluateJavaScript(
                """
                window.getSelection().removeAllRanges(); document.dispatchEvent(new \
                MouseEvent('mouseup',{bubbles:true}))
                """
            )
    }

    private static func selectQuote(_ session: ReaderSession, view: WKWebView) async throws
    {
        _ = try await view.evaluateJavaScript("""
            (()=>{const p=[...document.querySelectorAll('p')].find(p=>p.textContent.startsWith('Select this sentence'));
            const range=document.createRange(); range.setStart(p.firstChild,0);
            range.setEnd(p.firstChild,p.firstChild.textContent.indexOf('.')+1);
            const selection=window.getSelection();selection.removeAllRanges();selection.addRange(range);
            document.dispatchEvent(new MouseEvent('mouseup',{bubbles:true}));})()
            """)
        for _ in 0 ..< 100
        {
            if session.annotations.ready && !session.annotations.selection.isEmpty
            {
                break
            }
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    private static func notes(_ session: ReaderSession, view: WKWebView) async throws
    {
        session.annotations.inspectorTab = "Notes"
        session.annotations.editNotes("""
            # Reading notes

            - Compare the table values.
            - Review the companion guide.
            - Return to the highlighted passage.

            Source Markdown stays unchanged until Export.
            """)
        guard await session.annotations.drain()
        else
        {
            throw ReaderFailure.unavailable
        }
        try await jump(session, view: view, heading: "2-tables-and-code")
    }

    private static func jump(_ session: ReaderSession, view: WKWebView, heading: String) async throws
    {
        session.command(["type": "jump", "id": heading])
        try await waitDOM(view, "!!document.getElementById('\(heading)')")
        try await Task.sleep(for: .milliseconds(200))
    }

    private static func waitDOM(_ view: WKWebView, _ expression: String) async throws
    {
        for _ in 0 ..< 200
        {
            if try await view.evaluateJavaScript(expression) as? Bool == true
            {
                return
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        throw ReaderFailure.unavailable
    }
}
