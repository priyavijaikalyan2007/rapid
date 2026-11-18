// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 0e5457ad-9b83-4875-9392-0517c554518f
// COMPONENT: Native reader lifecycle acceptance
// PURPOSE: Exercise actual tabs, workspaces, file observation, restoration, and renderer release with synthetic files.
import AppKit
import WebKit

@MainActor enum ReviewLifecycleSmoke
{
    static func run(application: AppDelegate) async throws -> [String: Any]
    {
        let root = try fixture()
        let a = root.appendingPathComponent("A/Readme.md")
        let b = root.appendingPathComponent("B/Readme.md")
        let first = application.createWindow(file: a, folder: a.deletingLastPathComponent())
        try await rendered(first.session, heading: "alpha")
        var report = try await tabs(application, first: first, other: b)
        let restored = try await restore(application, first: first)
        report["tabSnapshotRestored"] = restored.session.state?.zoom == 1.4 && restored.session.preferences
            .bodySize == 19
        report["findGetsKeyboardFocus"] = await findFocus(application, controller: restored)
        report.merge(try await changes(restored.session, file: a))
        { _, new in
            new
        }
        report.merge(try await workspaces(restored.session, root: root))
        { _, new in
            new
        }
        report["displayCount"] = NSScreen.screens.count
        report["passed"] = report.filter
        {
            $0.key != "displayCount"
        }.values.allSatisfy
        {
            $0 as? Bool == true
        }
        for controller in application.controllers.reversed()
        {
            _ = await controller.session.annotations.drain()
            controller.close()
        }
        return report
    }

    private static func fixture() throws -> URL
    {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("monomark-lifecycle-\(UUID())")
        for name in ["A", "B", "Empty"]
        {
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent(name),
                withIntermediateDirectories: true
            )
        }
        try "# Alpha\n\n## Chapter\n\nFirst workspace.\n".write(
            to: root.appendingPathComponent("A/Readme.md"),
            atomically: true,
            encoding: .utf8
        )
        try "# Beta\n\nSecond workspace.\n".write(
            to: root.appendingPathComponent("B/Readme.md"),
            atomically: true,
            encoding: .utf8
        )
        return root
    }

    private static func tabs(
        _ application: AppDelegate,
        first: ReaderWindowController,
        other: URL
    ) async throws -> [String: Any]
    {
        let second = application.createWindow(file: other, folder: other.deletingLastPathComponent(), tabbedWith: first)
        try await rendered(second.session, heading: "beta")
        let released = await until
        {
            first.session.isSuspended && first.session.webView == nil
        }
        let grouped = first.window?.tabGroup === second.window?.tabGroup
        first.window?.makeKeyAndOrderFront(nil)
        try await rendered(first.session, heading: "alpha")
        return [
            "nativeTabsGrouped": grouped,
            "inactiveRendererReleased": released,
            "reactivatedRenderer": first.session.webView != nil && !first.session.isSuspended,
            "duplicateFilenamesIndependent": first.session.url != second.session.url &&
                first.window?.representedURL != second.window?.representedURL
        ]
    }

    private static func restore(
        _ application: AppDelegate,
        first: ReaderWindowController
    ) async throws -> ReaderWindowController
    {
        guard var saved = first.session.state
        else
        {
            throw ReaderFailure.unavailable
        }
        saved.zoom = 1.4
        saved.anchor = "chapter"
        saved.preferences = ReaderPreferences()
        saved.preferences?.bodySize = 19
        let decoded = try JSONDecoder().decode([ReadingState].self, from: JSONEncoder().encode([saved]))[0]
        let controller = ReaderWindowController(application: application)
        application.controllers.append(controller)
        controller.pendingRecord = decoded
        controller.session.isSuspended = true
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        try await rendered(controller.session, heading: "alpha")
        return controller
    }

    private static func findFocus(_ application: AppDelegate, controller: ReaderWindowController) async -> Bool
    {
        controller.window?.makeKeyAndOrderFront(nil)
        application.find(nil)
        let focused = await until
        {
            (controller.window?.firstResponder as? NSTextView)?.isFieldEditor == true
        }
        controller.session.showFind = false
        return focused
    }

    private static func seedNotes(_ session: ReaderSession) async throws
    {
        await session.annotations.waitForLoad()
        session.annotations.editNotes("Lifecycle notes survive.")
        session.annotations.selection = [TextAnchor(blockID: "alpha", quote: "Alpha", prefix: "", suffix: "", start: 0)]
        session.annotations.addSelection()
        guard await session.annotations.drain()
        else
        {
            throw ReaderFailure.unavailable
        }
    }

    private static func changes(_ session: ReaderSession, file: URL) async throws -> [String: Any]
    {
        try await seedNotes(session)
        session.preferences.autoReload = true
        try "# Automatic change\n\nNew source.\n".write(to: file, atomically: true, encoding: .utf8)
        try await rendered(session, heading: "automatic-change")
        session.preferences.autoReload = false
        try "# Manual change\n\nFresh source.\n".write(to: file, atomically: true, encoding: .utf8)
        guard await until({
            session.hasExternalChanges
        }) else
        {
            throw ReaderFailure.unavailable
        }
        let retained = try await hasHeading(session, "automatic-change")
        session.refresh(reindexReferences: false)
        try await rendered(session, heading: "manual-change")
        var report = try await rename(session, file: file)
        report["automaticReload"] = true
        report["manualReloadPreservesOldView"] = retained
        report["manualRefresh"] = true
        return report
    }

    private static func rename(_ session: ReaderSession, file: URL) async throws -> [String: Any]
    {
        let oldID = session.state?.id
        let renamed = file.deletingLastPathComponent().appendingPathComponent("Renamed.md")
        try FileManager.default.moveItem(at: file, to: renamed)
        session.open(renamed, folder: renamed.deletingLastPathComponent())
        try await rendered(session, heading: "manual-change")
        await session.annotations.waitForLoad()
        let notes = session.annotations.text == "Lifecycle notes survive." && session.annotations.records.count == 1
        let identity = oldID == session.state?.id && session.state?.path == renamed.path
        let deletion = try await deletedFile(session, file: renamed)
        return [
            "renameRetainsIdentity": identity,
            "notesSurviveReplacementAndRename": notes,
            "deletedFileRecovers": deletion
        ]
    }

    private static func deletedFile(_ session: ReaderSession, file: URL) async throws -> Bool
    {
        try FileManager.default.removeItem(at: file)
        guard await until({
            session.hasExternalChanges
        }) else
        {
            return false
        }
        session.refresh(reindexReferences: false)
        guard await until({
            session.message.contains("could not")
        }) else
        {
            return false
        }
        let clear = try await session.webView?
            .evaluateJavaScript("!document.getElementById('manual-change')") as? Bool == true
        try "# Recovered source\n\nReady.\n".write(to: file, atomically: true, encoding: .utf8)
        session.refresh(reindexReferences: false)
        try await rendered(session, heading: "recovered-source")
        return clear
    }

    private static func workspaces(_ session: ReaderSession, root: URL) async throws -> [String: Any]
    {
        session.openWorkspace(root.appendingPathComponent("B"))
        try await rendered(session, heading: "beta")
        let folder = session.root == root.appendingPathComponent("B")
        session.openWorkspace(root.appendingPathComponent("Empty"))
        guard await until({
            session.url == nil && session.root == root.appendingPathComponent("Empty")
        }) else
        {
            throw ReaderFailure.unavailable
        }
        let clear = try await session.webView?
            .evaluateJavaScript("window.MonoMark.metrics().blocks===0") as? Bool == true
        session.openWorkspace(root.appendingPathComponent("B"))
        try await rendered(session, heading: "beta")
        return ["workspaceSwitch": folder, "emptyWorkspaceClearsDocument": clear, "workspaceReopens": true]
    }

    private static func hasHeading(_ session: ReaderSession, _ heading: String) async throws -> Bool
    {
        try await session.webView?.evaluateJavaScript("!!document.getElementById('\(heading)')") as? Bool == true
    }

    private static func rendered(_ session: ReaderSession, heading: String) async throws
    {
        for _ in 0 ..< 150
        {
            if session.rendererReady, !session.isLoading, try await hasHeading(session, heading)
            {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        let state = try? await session.webView?.evaluateJavaScript(
            "({metrics:window.MonoMark?.metrics(),headings:[...document.querySelectorAll('h1')].map(x=>x.id)})"
        )
        throw NSError(
            domain: "MonoMarkLifecycle",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "The synthetic \(heading) document did not render.",
                "readerStatus": session.message,
                "loading": session.isLoading,
                "ready": session.rendererReady,
                "suspended": session.isSuspended,
                "state": String(describing: state),
                "zoom": session.state?.zoom ?? 0
            ]
        )
    }

    private static func until(_ condition: () -> Bool) async -> Bool
    {
        for _ in 0 ..< 70
        {
            if condition()
            {
                return true
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return false
    }
}
