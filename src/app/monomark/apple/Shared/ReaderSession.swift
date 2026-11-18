// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9c7ffef3-390a-407c-85c4-80e909b95a8f
// Created: 2026
// COMPONENT: MonoMark native UI
// PURPOSE: Own native reading state, cancellable loads, history, and navigation policy.
// RELATES: MonoMark product and implementation specifications
// FLOW: Native command -> session -> validated renderer bridge.

import Foundation
import SwiftUI
import WebKit
import OSLog
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The main actor owns presentation, while file and database operations run outside the UI path.
@MainActor
final class ReaderSession: ObservableObject
{
    let annotations = AnnotationController()
    let workspaces = WorkspaceLibrary.shared
    @Published var url: URL?
    @Published var root: URL?
    @Published var outline: [NavigationEntry] = []
    @Published var links: [DocumentLink] = []
    @Published var history: [ReadingState] = []
    @Published var entries: [FolderEntry] = []
    @Published var section = "Files"
    @Published var message = "Open a Markdown file or folder to begin."
    @Published var isLoading = false
    @Published var showSettings = false
    @Published var showExportOptions = false
    @Published var showFind = false
    @Published var query = ""
    @Published var historyQuery = ""
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var preferences = ReaderPreferences()
    @Published var showSidebar = true
    @Published var rendererReady = false
    @Published var isSuspended = false
    weak var webView: WKWebView?
    var openNewTab: ((URL, URL?) -> Void)?
    var titleChanged: ((String) -> Void)?
    var printAction: (() -> Void)?
    var exportAction: ((ReadingExportOptions, ReadingExportDestination) -> Void)?
    var smokeRendered: (() -> Void)?
    var state: ReadingState?
    private var store: HistoryStore?
    var generation = UUID()
    var scopes: [URL] = []
    private var locations: [(URL, String?)] = []
    private var locationIndex = -1
    private var forgotten = false
    private let logger = Logger(subsystem: "us.outcrop.MonoMark", category: "Reader")
    var watcher: DocumentWatcher?
    @Published var hasExternalChanges = false
    @Published var referenceIndexTruncated = false
    var referenceIndex: WorkspaceFileIndex?
    var referenceTask: Task<Void, Never>?
    var appliedFileLinks = false
    var appliedSectionLinks = false
    var lastCopyRequest: [String: Any] = [:]
    var documentEpoch: String
    {
        generation.uuidString
    }

    init()
    {
        do
        {
            let base: URL
            if ProcessInfo.processInfo.arguments.contains("--smoke-test") || ProcessInfo.processInfo.arguments
                .contains("--demo")
            {
                base = FileManager.default.temporaryDirectory
                    .appendingPathComponent("monomark-smoke-\(UUID().uuidString)")
            }
            else
            {
                base = URL.applicationSupportDirectory.appendingPathComponent("MonoMark")
            }
            store = try HistoryStore(url: base.appendingPathComponent("history.sqlite"))
            if let data = UserDefaults.standard.data(forKey: "reader-defaults"),
               let saved = try? JSONDecoder().decode(ReaderPreferences.self, from: data)
            {
                preferences = saved
            }
            preferences.normalize()
        }
        catch
        {
            message = ReaderFailure.invalidStore.localizedDescription
        }
        refreshHistory()
        annotations.changed = { [weak self] in
            self?.sendAnnotations()
        }
    }

    /// Opening a document is the only operation that creates or updates its visit record.
    func open(
        _ file: URL,
        folder: URL? = nil,
        fragment: String? = nil,
        addHistory: Bool = true,
        resume: ReadingState? = nil
    )
    {
        checkpoint()
        generation = UUID()
        let ticket = generation
        isLoading = true
        forgotten = false
        retainScope(file)
        if let folder
        {
            retainScope(folder)
        }
        Task
        {
            guard await annotations.drain()
            else
            {
                message = annotations.error ?? "The reading notes could not be saved."
                isLoading = false
                return
            }
            do
            {
                let store = self.store
                let result = try await Task.detached(priority: .userInitiated)
                {
                    let identity = try DocumentAccess.identity(file)
                    _ = try file.resourceValues(forKeys: [.fileSizeKey])
                    return (identity, try store?.state(id: identity, path: file.path))
                }.value
                guard ticket == generation
                else
                {
                    return
                }
                self.url = file
                annotations.open(document: result.0, path: file.standardizedFileURL.path)
                root = folder ?? file
                state = result.1 ?? resume ?? ReadingState(
                    id: result.0,
                    path: file.path,
                    accessedAt: Date().timeIntervalSince1970
                )
                state?.path = file.path
                state?.id = result.0
                state?.accessedAt = Date().timeIntervalSince1970
                state?.rootPath = root?.path
                state?.bookmark = bookmark(file)
                state?.rootBookmark = root.flatMap(bookmark)
                preferences = ReaderPreferences.forDocument(
                    saved: state?.preferences,
                    defaultsData: UserDefaults.standard
                        .data(forKey: "reader-defaults")
                )
                preferences.normalize()
                if addHistory
                {
                    locations = Array(locations.prefix(locationIndex + 1)) + [(file, fragment)]
                    locationIndex = locations.count - 1
                }
                if let fragment
                {
                    state?.anchor = fragment
                    state?.offset = 0
                }
                titleChanged?(file.lastPathComponent)
                outline = []
                links = []
                if folder != nil
                {
                    await loadFolder(root!)
                }
                await prepareImplicitReferences()
                guard ticket == generation
                else
                {
                    return
                }
                if rendererReady
                {
                    loadRenderer()
                }
                guard ticket == generation
                else
                {
                    return
                }
                checkpoint()
                releaseUnusedScopes(keeping: [file, root ?? file])
                rememberWorkspace()
                watch(file)
                logger.info("Opened local document")
            }
            catch
            {
                fail(error)
            }
        }
    }

    func loadRenderer()
    {
        guard url != nil
        else
        {
            return
        }
        appliedFileLinks = preferences.implicitFileLinks
        appliedSectionLinks = preferences.implicitSectionLinks
        command(["type": "preferences", "value": rendererPreferences()])
        command([
            "type": "load",
            "references": rendererReferences(),
            "anchor": state?.anchor ?? "",
            "offset": state?.offset ?? 0,
            "progress": state?.progress ?? 0,
            "zoom": state?.zoom ?? 1,
            "epoch": documentEpoch
        ])
    }

    func command(_ value: [String: Any])
    {
        webView?.callAsyncJavaScript(
            "window.MonoMark.command(command)",
            arguments: ["command": value],
            in: nil,
            in: .page
        )
        { [weak self] result in
            if case .failure = result
            {
                self?.message = "The document renderer is not ready. Try reopening the document."
            }
        }
    }

    func receive(_ message: [String: Any])
    {
        guard let type = message["type"] as? String
        else
        {
            return
        }
        if type != "ready", message["epoch"] as? String != documentEpoch
        {
            return
        }
        switch type
        {
        case "ready": rendererReady = true
            loadRenderer()
        case "index": indexed(message)
        case "visible": isLoading = false
            smokeRendered?()
        case "pages":
            totalPages = max(1, min(10000000, message["total"] as? Int ?? 1))
            currentPage = max(1, min(totalPages, message["current"] as? Int ?? 1))
        case "position": updatePosition(message)
        case "navigate": navigate(message["href"] as? String ?? "", newTab: message["newTab"] as? Bool ?? false)
        case "preview": preview(message["href"] as? String ?? "")
        case "copy": copy(message["href"] as? String ?? "")
        case "copyText":
            if let text = message["text"] as? String, text.utf8.count <= 4 * 1024 * 1024
            {
                copy(text)
            }
        case "copyPNG": copyPNG(message)
        case "selection": receiveSelection(message)
        case "annotationStatus": annotations.visibleIDs = Set((message["attached"] as? [String] ?? []).prefix(20000))
        case "annotationSelected": annotations.selectAnnotation(message["id"] as? String ?? "")
        case "status": self.message = String((message["message"] as? String ?? "").prefix(500))
            isLoading = false
        case "printReady": printAction?()
        default: break
        }
    }

    private func indexed(_ data: [String: Any])
    {
        guard let rawOutline = data["outline"], let rawLinks = data["links"],
              let a = try? JSONSerialization.data(withJSONObject: rawOutline),
              let b = try? JSONSerialization.data(withJSONObject: rawLinks)
        else
        {
            return
        }
        outline = (try? JSONDecoder().decode([NavigationEntry].self, from: a)) ?? []
        links = (try? JSONDecoder().decode([DocumentLink].self, from: b)) ?? []
        sendAnnotations()
        message = "\(data["blocks"] as? Int ?? 0) blocks · \(Int(data["duration"] as? Double ?? 0)) ms to index"
    }

    private func updatePosition(_ data: [String: Any])
    {
        guard state != nil
        else
        {
            return
        }
        state?.anchor = String((data["anchor"] as? String ?? "").prefix(512))
        state?.offset = ReaderPreferences.bound(data["offset"] as? Double ?? 0, -100000 ... 100000, fallback: 0)
        state?.progress = ReaderPreferences.bound(data["progress"] as? Double ?? 0, 0 ... 1, fallback: 0)
        state?.zoom = ReaderPreferences.bound(data["zoom"] as? Double ?? 1, 0.5 ... 3, fallback: 1)
        checkpoint()
    }

    func checkpoint()
    {
        guard var saved = state, !forgotten, let store
        else
        {
            return
        }
        saved.preferences = preferences
        state = saved
        Task
        {
            do
            {
                try await Task.detached(priority: .utility)
                {
                    try store.record(saved)
                }.value
                if section == "History"
                {
                    refreshHistory()
                }
            }
            catch
            {
                fail(ReaderFailure.invalidStore)
            }
        }
    }

    func refreshHistory(append: Bool = false)
    {
        guard let store
        else
        {
            return
        }
        let query = historyQuery
        let offset = append ? history.count : 0
        Task
        {
            do
            {
                let page = try await Task.detached
                {
                    try store.page(query: query, offset: offset, limit: 100)
                }.value
                guard query == historyQuery
                else
                {
                    return
                }
                if append
                {
                    history += page
                }
                else
                {
                    history = page
                }
            }
            catch
            {
                fail(error)
            }
        }
    }

    func reopen(_ record: ReadingState)
    {
        let file = resolve(record.bookmark) ?? URL(fileURLWithPath: record.path)
        let folder = resolve(record.rootBookmark) ?? record.rootPath.map
        {
            URL(fileURLWithPath: $0)
        }
        open(file, folder: folder)
    }

    func forget(_ record: ReadingState)
    {
        if state?.id == record.id
        {
            forgotten = true
        }
        do
        {
            try store?.forget(record.id)
            refreshHistory()
        }
        catch
        {
            fail(error)
        }
    }

    func clearHistory()
    {
        forgotten = true
        do
        {
            try store?.clear()
            refreshHistory()
        }
        catch
        {
            fail(error)
        }
    }

    func go(_ direction: Int)
    {
        let next = locationIndex + direction
        guard locations.indices.contains(next)
        else
        {
            return
        }
        locationIndex = next
        open(locations[next].0, folder: root, fragment: locations[next].1, addHistory: false)
    }

    func close()
    {
        if var saved = state, !forgotten
        {
            saved.preferences = preferences
            do
            {
                try store?.record(saved)
            }
            catch
            {
                fail(ReaderFailure.invalidStore)
            }
        }
        watcher?.cancel()
        watcher = nil
        referenceTask?.cancel()
        referenceTask = nil
        for scope in scopes
        {
            scope.stopAccessingSecurityScopedResource()
        }
        scopes = []
    }

    func dictionary<T: Encodable>(_ value: T) -> [String: Any]
    {
        guard let data = try? JSONEncoder().encode(value)
        else
        {
            return [:]
        }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }

    func fail(_ error: Error)
    {
        isLoading = false
        message = error.localizedDescription
        logger.error("Local reader operation failed")
    }
}
