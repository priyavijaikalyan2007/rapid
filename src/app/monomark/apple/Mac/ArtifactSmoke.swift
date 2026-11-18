// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 0d47f045-3b6e-4c1d-b63b-1d41c4182949
// COMPONENT: Native artifact acceptance runner
// PURPOSE: Verify actual WebKit PNG snapshots through an isolated native pasteboard.
import AppKit
import WebKit

@MainActor enum ArtifactSmoke
{
    static func run(session: ReaderSession, output: String) async throws -> [String: Any]
    {
        guard let view = session.webView, let source = session.url
        else
        {
            throw ReaderFailure.unavailable
        }
        let original = try Data(contentsOf: source)
        try await waitForRichContent(view)
        session.command(["type": "appearance", "mode": "light"])
        try await Task.sleep(for: .milliseconds(250))
        var artifacts: [String: Any] = [:]
        for kind in ["equation", "image", "diagram"]
        {
            artifacts[kind] = try await capture(kind, session: session, view: view, output: output)
        }
        let textWins = try await newerTextWins(session)
        let hidden = try await hiddenCaptures(session: session, view: view, output: output)
        session.lastCopyRequest = [:]
        session.copyPNG(["x": 0.0, "y": 0.0, "width": 80.0, "height": 40.0])
        session.open(
            source.deletingLastPathComponent().appendingPathComponent("Other.md"),
            folder: source.deletingLastPathComponent()
        )
        try await Task.sleep(for: .seconds(1))
        let cancelled = session.lastCopyRequest["pasteboardVerified"] as? Bool != true
        let unchanged = try Data(contentsOf: source) == original
        return [
            "passed": cancelled && unchanged && textWins && hidden["windowStayedHidden"] as? Bool == true,
            "hiddenWindowArtifacts": hidden,
            "newerTextWins": textWins,
            "artifacts": artifacts,
            "replacementCancelledCopy": cancelled,
            "sourceUnchanged": unchanged
        ]
    }

    private static func newerTextWins(_ session: ReaderSession) async throws -> Bool
    {
        session.lastCopyRequest = [:]
        session.copyPNG(["x": 0.0, "y": 0.0, "width": 80.0, "height": 40.0])
        session.copy("A newer text copy wins.")
        try await Task.sleep(for: .seconds(1))
        return session.lastCopyRequest["textHash"] as? String == DocumentStamp.make("A newer text copy wins.") &&
            session.lastCopyRequest["pasteboardVerified"] as? Bool != true
    }

    private static func hiddenCaptures(
        session: ReaderSession,
        view: WKWebView,
        output: String
    ) async throws -> [String: Any]
    {
        guard let window = view.window
        else
        {
            throw ReaderFailure.unavailable
        }
        window.orderOut(nil)
        defer { window.makeKeyAndOrderFront(nil) }
        try await Task.sleep(for: .milliseconds(250))
        var report: [String: Any] = [:]
        for kind in ["equation", "image", "diagram"]
        {
            report[kind] = try await capture(kind, session: session, view: view, output: output + ".hidden")
        }
        report["windowStayedHidden"] = !window.isVisible
        return report
    }

    private static func waitForRichContent(_ view: WKWebView) async throws
    {
        for _ in 0 ..< 60
        {
            let ready = try await view.evaluateJavaScript("""
                !!document.querySelector('.katex') && !!document.querySelector('[data-mermaid] svg') &&
                !!document.querySelector('img')?.complete && document.querySelector('img').naturalWidth > 0
                """) as? Bool
            if ready == true
            {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw ReaderFailure.unavailable
    }

    private static func capture(
        _ kind: String,
        session: ReaderSession,
        view: WKWebView,
        output: String
    ) async throws -> [String: Any]
    {
        session.lastCopyRequest = [:]
        _ = try await view.evaluateJavaScript(
            "document.querySelector('.monomark-artifact-\(kind) button[title*=PNG]')?.click()"
        )
        for _ in 0 ..< 60
        {
            if session.lastCopyRequest["pasteboardVerified"] as? Bool == true
            {
                let arguments = ProcessInfo.processInfo.arguments
                guard let index = arguments.firstIndex(of: "--smoke-test")
                else
                {
                    throw ReaderFailure.unavailable
                }
                let png = try Data(contentsOf: URL(fileURLWithPath: arguments[index + 1] + ".artifact.png"))
                guard let bitmap = NSBitmapImageRep(data: png)
                else
                {
                    throw ReaderFailure.unavailable
                }
                try png.write(to: URL(fileURLWithPath: output + ".\(kind).png"))
                guard pixelsMatch(bitmap, kind: kind)
                else
                {
                    throw ReaderFailure.unavailable
                }
                return [
                    "pasteboardRoundTrip": true,
                    "pixelsVerified": true,
                    "width": bitmap.pixelsWide,
                    "height": bitmap.pixelsHigh,
                    "bytes": png.count
                ]
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw ReaderFailure.unavailable
    }

    private static func pixelsMatch(_ bitmap: NSBitmapImageRep, kind: String) -> Bool
    {
        if kind == "image"
        {
            guard let left = bitmap.colorAt(x: bitmap.pixelsWide / 4, y: bitmap.pixelsHigh / 2)?
                .usingColorSpace(.deviceRGB),
                let right = bitmap.colorAt(x: bitmap.pixelsWide * 3 / 4, y: bitmap.pixelsHigh / 2)?
                    .usingColorSpace(.deviceRGB)
            else
            {
                return false
            }
            return left.redComponent > 0.8 && left.blueComponent < 0.2 &&
                right.blueComponent > 0.8 && right.redComponent < 0.2
        }
        for x in stride(from: 0, to: bitmap.pixelsWide, by: max(1, bitmap.pixelsWide / 80))
        {
            for y in stride(from: 0, to: bitmap.pixelsHigh, by: max(1, bitmap.pixelsHigh / 40))
            {
                if let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
                   min(color.redComponent, color.greenComponent, color.blueComponent) < 0.8
                {
                    return true
                }
            }
        }
        return false
    }
}
