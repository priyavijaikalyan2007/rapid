// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 2e7bb69d-e497-46ab-acfb-b4a65cbfbba7
// COMPONENT: Native implicit-link acceptance
// PURPOSE: Verify workspace resolution, new-tab dispatch, and section jumps through real WebKit.
import Foundation
import WebKit

@MainActor enum ReviewLinkSmoke
{
    static func run(session: ReaderSession) async throws -> [String: Any]
    {
        let file = try fixture()
        let original = try Data(contentsOf: file)
        session.open(file, folder: file.deletingLastPathComponent())
        try await wait
        {
            session.url?.lastPathComponent == "00-Reader.md" && !session.isLoading && session.annotations.ready
        }
        session.preferences.implicitFileLinks = true
        session.preferences.implicitSectionLinks = true
        session.updatePreferences()
        try await wait
        {
            session.referenceIndex != nil && session.appliedSectionLinks
        }
        guard let view = session.webView
        else
        {
            throw ReaderFailure.unavailable
        }
        try await waitDOM(view, "document.querySelectorAll('a[data-new-tab=true]').length === 2")
        let originalAction = session.openNewTab
        var opened: [URL] = []
        session.openNewTab = { file, _ in
            opened.append(file)
        }
        defer { session.openNewTab = originalAction }
        _ = try await view.evaluateJavaScript("document.querySelectorAll('a[data-new-tab=true]')[0].click()")
        try await wait
        {
            opened.count == 1
        }
        _ = try await view.evaluateJavaScript("document.querySelectorAll('a[data-new-tab=true]')[1].click()")
        try await wait
        {
            opened.count == 2
        }
        _ = try await view.evaluateJavaScript("document.querySelector('a[href=\"#9-destination\"]').click()")
        try await waitDOM(view, "!!document.getElementById('9-destination') && window.scrollY > 500")
        let limited = try await view.evaluateJavaScript("window.MonoMark.metrics().mounted <= 80") as? Bool == true
        return [
            "fileNewTabDispatch": opened.first?.lastPathComponent == "Other.md",
            "spaceFilename": opened.last?.lastPathComponent == "My File.md",
            "numberedSectionJump": true,
            "boundedViewport": limited,
            "sourceUnchanged": try Data(contentsOf: file) == original
        ]
    }

    private static func fixture() throws -> URL
    {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("monomark-links-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let file = root.appendingPathComponent("00-Reader.md")
        let text =
            "# Reader links\n\nClipboard test sentence.\n\nSee Other.md and `My File.md`.\n\nSee §9, #9.1 and $9.\n\n" +
            (1 ... 100).map
            {
                "Paragraph \($0). Synthetic reading text.\n\n"
            }.joined() +
            "## 9. Destination\n\nSection destination.\n\n### 9.1 Details\n\nDetails.\n"
        try Data(text.utf8).write(to: file)
        try Data("# Other\n\nAnother document.\n".utf8).write(to: root.appendingPathComponent("Other.md"))
        try Data("# Space filename\n\nA document with spaces.\n".utf8)
            .write(to: root.appendingPathComponent("My File.md"))
        return file
    }

    private static func wait(_ condition: () -> Bool) async throws
    {
        for _ in 0 ..< 100
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
        for _ in 0 ..< 100
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
