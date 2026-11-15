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
    @Published var inspectorTab = "Annotations"
    @Published var annotationQuery = ""
    @Published var collapsedIDs: Set<String> = []
    @Published var revealToken = UUID()
    @Published var noteQuery = ""
    {
        didSet { refreshNoteMatches(selectFirst: true) }
    }

    @Published private(set) var noteMatches: [NSRange] = []
    @Published private(set) var noteSelection: NSRange?
    @Published private(set) var noteSelectionGeneration = UUID()
    @Published var noteSearchFocus = UUID()
    var notesEditorFocused = false
    var notesSearchFocused = false
    private var noteMatchIndex = -1
    var changed: (() -> Void)?
    private var store: AnnotationStore?
    private var document = ""
    private var path = ""
    private var generation = UUID()
    var documentToken: UUID
    {
        generation
    }

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
        collapsedIDs = []
        annotationQuery = ""
        noteQuery = ""
        ready = false
        reload()
    }

    /// Call only after drain succeeds, so an empty workspace cannot display or edit the previous file's notes.
    func detach()
    {
        loading?.cancel()
        noteTimer?.cancel()
        generation = UUID()
        document = ""
        path = ""
        records = []
        text = ""
        queuedText = ""
        selection = []
        selectedID = nil
        visibleIDs = []
        collapsedIDs = []
        annotationQuery = ""
        noteQuery = ""
        ready = false
        error = nil
        hasFailedEdits = false
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
                refreshNoteMatches(selectFirst: false)
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
        update(annotation)
        annotationQuery = ""
        selectAnnotation(annotation.id)
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
        refreshNoteMatches(selectFirst: false)
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

    var filteredRecords: [ReadingAnnotation]
    {
        guard !annotationQuery.isEmpty
        else
        {
            return records
        }
        return records.filter
        { record in
            record.comment.range(of: annotationQuery, options: [.caseInsensitive, .diacriticInsensitive]) != nil ||
                record.anchors.contains { $0.quote.range(
                    of: annotationQuery,
                    options: [.caseInsensitive, .diacriticInsensitive]
                ) != nil }
        }
    }

    func isExpanded(_ id: String) -> Bool
    {
        !collapsedIDs.contains(id)
    }

    func expandAll()
    {
        collapsedIDs = []
    }

    func collapseAll()
    {
        collapsedIDs = Set(records.map(\.id))
    }

    func setExpanded(_ id: String, _ value: Bool)
    {
        if value
        {
            collapsedIDs.remove(id)
        }
        else
        {
            collapsedIDs.insert(id)
        }
    }

    func selectAnnotation(_ id: String)
    {
        guard records.contains(where: {
            $0.id == id
        }) else
        {
            return
        }
        if !filteredRecords.contains(where: {
            $0.id == id
        })
        {
            annotationQuery = ""
        }
        collapsedIDs.remove(id)
        inspectorTab = "Annotations"
        selectedID = id
        revealToken = UUID()
        shown = true
    }

    private func refreshNoteMatches(selectFirst: Bool)
    {
        noteMatches = TextSearch.ranges(in: text, query: noteQuery)
        noteMatchIndex = -1
        if selectFirst
        {
            findNote(1)
        }
    }

    func findNote(_ direction: Int)
    {
        guard !noteMatches.isEmpty
        else
        {
            noteSelection = nil
            return
        }
        if noteMatchIndex < 0
        {
            noteMatchIndex = direction < 0 ? noteMatches.count - 1 : 0
        }
        else
        {
            noteMatchIndex = (noteMatchIndex + (direction < 0 ? -1 : 1) + noteMatches.count) % noteMatches.count
        }
        noteSelection = noteMatches[noteMatchIndex]
        noteSelectionGeneration = UUID()
    }

    var noteMatchLabel: String
    {
        noteMatches.isEmpty ? "No matches" : "\(max(0, noteMatchIndex + 1)) of \(noteMatches.count)\(noteMatches.count == 10000 ? "+" : "")"
    }
}
