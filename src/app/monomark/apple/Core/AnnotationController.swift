// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 49151397-6ed9-4775-b591-74af289c5200
// COMPONENT: Native reading annotations
// PURPOSE: Keep highlights, comments, and notes separate from source Markdown.
// FLOW: Native action -> ordered local persistence -> reader decoration.

import Foundation
import Combine

/// Ordered writes preserve each edit. A failed draft stays visible and prevents silent document closure.
@MainActor
final class AnnotationController: ObservableObject
{
    @Published private(set) var records: [ReadingAnnotation] = []
    @Published private(set) var text = ""
    @Published private(set) var format = "markdown"
    @Published private(set) var ready = false
    @Published private(set) var pending = 0
    @Published private(set) var notesDirty = false
    @Published private(set) var error: String?
    private(set) var hasFailedEdits = false
    @Published var selection: [TextAnchor] = []
    @Published var shown = false
    @Published var selectedID: String?
    @Published var color = "yellow"
    @Published var visibleIDs: Set<String> = []
    var changed: (() -> Void)?
    private var store: AnnotationStore?
    private var document = ""
    private var path = ""
    private var generation = UUID()
    private var tail: Task<Void, Never>?
    private var loading: Task<Void, Never>?
    private var noteTimer: Task<Void, Never>?
    private var queuedText = ""

    init(databaseURL: URL? = nil)
    {
        let testing = ProcessInfo.processInfo.arguments.contains("--smoke-test") ||
            ProcessInfo.processInfo.arguments.contains("--demo")
        let base = testing ? FileManager.default.temporaryDirectory
            .appendingPathComponent("monomark-notes-\(UUID().uuidString)") :
            URL.applicationSupportDirectory.appendingPathComponent("MonoMark")
        do
        {
            store = try AnnotationStore(url: databaseURL ?? base.appendingPathComponent("annotations.sqlite"))
        }
        catch
        {
            self.error = error.localizedDescription
        }
    }

    func open(document: String, path: String)
    {
        self.document = document
        self.path = path
        generation = UUID()
        selection = []
        selectedID = nil
        records = []
        text = ""
        ready = false
        reload()
    }

    func reload()
    {
        noteTimer?.cancel()
        notesDirty = false
        guard let store
        else
        {
            return
        }
        let id = document
        let file = path
        let ticket = generation
        let previous = tail
        loading = Task
        {
            await previous?.value
            do
            {
                let saved = try await store.load(document: id, path: file)
                guard ticket == generation
                else
                {
                    return
                }
                records = saved.annotations
                text = saved.text
                format = saved.format
                queuedText = saved.text
                notesDirty = false
                error = nil
                hasFailedEdits = false
                ready = true
                changed?()
            }
            catch
            {
                if ticket == generation
                {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func waitForLoad() async
    {
        await loading?.value
    }

    func addSelection()
    {
        guard ready, !selection.isEmpty
        else
        {
            return
        }
        let annotation = ReadingAnnotation(anchors: selection, color: color)
        selectedID = annotation.id
        shown = true
        update(annotation)
        selection = []
    }

    func update(_ value: ReadingAnnotation)
    {
        guard ready
        else
        {
            return
        }
        var annotation = value
        annotation.updatedAt = Date().timeIntervalSince1970
        let previous = records.first
        {
            $0.id == annotation.id
        }
        if let index = records.firstIndex(where: {
            $0.id == annotation.id
        })
        {
            records[index] = annotation
        }
        else
        {
            records.append(annotation)
        }
        let id = document
        let file = path
        let savedAnnotation = annotation
        enqueue
        {
            try await $0.put(savedAnnotation, expected: previous, document: id, path: file)
        }
        changed?()
    }

    func remove(_ annotation: ReadingAnnotation)
    {
        records.removeAll
        {
            $0.id == annotation.id
        }
        let id = document
        let file = path
        enqueue
        {
            try await $0.remove(annotation.id, document: id, path: file)
        }
        changed?()
    }

    func editNotes(_ value: String, format: String? = nil)
    {
        guard ready
        else
        {
            return
        }
        text = value
        if let format
        {
            self.format = format
        }
        notesDirty = true
        noteTimer?.cancel()
        noteTimer = Task
        {
            do
            {
                try await Task.sleep(for: .milliseconds(300))
            }
            catch
            {
                return
            }
            queueNotes()
        }
    }

    private func queueNotes()
    {
        guard ready, notesDirty
        else
        {
            return
        }
        let previous = queuedText
        let value = text
        let kind = format
        let id = document
        let file = path
        queuedText = value
        notesDirty = false
        enqueue
        {
            try await $0.writeNotes(value, format: kind, expected: previous, document: id, path: file)
        }
    }

    /// The explicit retry button lets this draft replace the latest stored note after a conflict.
    func retryDraft()
    {
        let id = document
        let file = path
        let draft = ReadingNotes(annotations: records, text: text, format: format)
        noteTimer?.cancel()
        notesDirty = false
        enqueue(recovering: true)
        {
            let saved = try await $0.load(document: id, path: file)
            try await $0.writeNotes(draft.text, format: draft.format, expected: saved.text, document: id, path: file)
            for annotation in saved.annotations where !draft.annotations.contains(where: {
                $0.id == annotation.id
            })
            {
                try await $0.remove(annotation.id, document: id, path: file)
            }
            for annotation in draft.annotations
            {
                try await $0.put(annotation, document: id, path: file)
            }
        }
    }

    func drain() async -> Bool
    {
        while true
        {
            noteTimer?.cancel()
            queueNotes()
            await tail?.value
            if pending == 0 && !notesDirty
            {
                return !hasFailedEdits
            }
        }
    }

    private func enqueue(
        recovering: Bool = false,
        _ operation: @escaping @Sendable (AnnotationStore) async throws -> Void
    )
    {
        guard let store
        else
        {
            return
        }
        let previous = tail
        pending += 1
        tail = Task
        {
            await previous?.value
            do
            {
                try await operation(store)
                if recovering
                {
                    error = nil
                    hasFailedEdits = false
                    queuedText = text
                }
            }
            catch
            {
                self.error = error.localizedDescription
                hasFailedEdits = true
                shown = true
            }
            pending -= 1
        }
    }
}
