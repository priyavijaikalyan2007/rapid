// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: a6a5cbc7-de5b-45f3-8e58-2a2f2a1fdf1d
// COMPONENT: Native reading annotations
// PURPOSE: Keep highlights, comments, and notes separate from source Markdown.
// FLOW: Native action -> ordered local persistence -> reader decoration.

import SwiftUI

/// Notes remain app-local until the user invokes an explicit export command.
struct AnnotationInspector: View
{
    @ObservedObject var session: ReaderSession
    @ObservedObject var controller: AnnotationController
    @FocusState private var noteSearchFocused: Bool
    @State private var discard = false

    var body: some View
    {
        Group
        {
            #if os(iOS)
            GeometryReader
            { geometry in
                VStack(alignment: .leading, spacing: 12)
                {
                    HStack
                    {
                        Text("Reading data").font(.headline)
                        Spacer()
                        Button("Done")
                        {
                            controller.shown = false
                        }.keyboardShortcut(.cancelAction)
                    }
                    ScrollView
                    {
                        readingData(editorHeight: max(120, geometry.size.height - 230))
                    }.scrollDismissesKeyboard(.interactively)
                }
            }
            #else
            readingData(editorHeight: nil)
            #endif
        }
        .padding()
        .onChange(of: controller.noteSearchFocus)
        { _, _ in
            noteSearchFocused = true
        }
        .onChange(of: noteSearchFocused)
        { _, focused in
            controller.notesSearchFocused = focused
        }
        .confirmationDialog("Discard the visible draft and reload saved notes?", isPresented: $discard)
        {
            Button("Discard Draft", role: .destructive)
            {
                controller.reload()
            }
        }
    }

    private func readingData(editorHeight: CGFloat?) -> some View
    {
        VStack(alignment: .leading, spacing: 12)
        {
            Picker("Reading data", selection: $controller.inspectorTab)
            {
                Text("Annotations").tag("Annotations")
                Text("Notes").tag("Notes")
            }.pickerStyle(.segmented)
            if controller.inspectorTab == "Annotations"
            {
                annotations.frame(height: editorHeight.map
                {
                    $0 + 90
                })
            }
            else
            {
                notes(editorHeight: editorHeight)
            }
            Divider()
            if let error = controller.error
            {
                Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled)
                HStack
                {
                    Button("Copy Draft")
                    {
                        session.copy(controller.text)
                    }
                    Button("Use This Draft")
                    {
                        controller.retryDraft()
                    }.disabled(!controller.ready)
                }
                Button("Reload Saved Notes")
                {
                    discard = true
                }.disabled(!controller.ready)
            }
            else
            {
                Text((controller.pending > 0 || controller.notesDirty) ? "Saving on this device…" :
                    "Saved on this device. Markdown source is unchanged.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var annotations: some View
    {
        VStack(alignment: .leading)
        {
            Text(controller.selection.isEmpty ? "Select document text to highlight it or add a comment." :
                "Selection: " + controller.selection.map(\.quote).joined(separator: " ").prefix(160))
                .font(.caption).foregroundStyle(.secondary)
            HStack
            {
                Picker("Highlight color", selection: $controller.color)
                {
                    ForEach(ReadingAnnotation.colors, id: \.self)
                    {
                        Text($0.capitalized).tag($0)
                    }
                }
                Button("Highlight")
                {
                    controller.addSelection()
                }.disabled(controller.selection.isEmpty)
            }
            HStack
            {
                TextField("Search annotations", text: $controller.annotationQuery).textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Search annotations")
                Button
                {
                    controller.expandAll()
                } label: {
                    Label("Expand All", systemImage: "chevron.down.2")
                }
                .labelStyle(.iconOnly).help("Expand all annotations")
                Button
                {
                    controller.collapseAll()
                } label: {
                    Label("Collapse All", systemImage: "chevron.up.2")
                }
                .labelStyle(.iconOnly).help("Collapse all annotations")
            }
            ScrollViewReader
            { proxy in
                ScrollView
                {
                    LazyVStack(alignment: .leading, spacing: 16)
                    {
                        ForEach(controller.filteredRecords)
                        { annotation in
                            AnnotationRow(
                                annotation: annotation,
                                attached: controller.visibleIDs.contains(annotation.id),
                                expanded: Binding(
                                    get: {
                                        controller.isExpanded(annotation.id)
                                    },
                                    set: {
                                        controller.setExpanded(annotation.id, $0)
                                    }
                                ),
                                update: controller.update,
                                remove: controller.remove
                            )
                            {
                                controller.selectAnnotation(annotation.id)
                                session.navigateAnnotation(annotation)
                            }.id(annotation.id)
                        }
                    }
                }
                .onChange(of: controller.revealToken)
                { _, _ in
                    if let id = controller.selectedID
                    {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
    }

    private func notes(editorHeight: CGFloat?) -> some View
    {
        VStack
        {
            Picker(
                "Notes format",
                selection: Binding(
                    get: {
                        controller.format
                    },
                    set: {
                        controller.editNotes(controller.text, format: $0)
                    }
                )
            )
            {
                Text("Markdown").tag("markdown")
                Text("Plain text").tag("plain")
            }
            HStack
            {
                TextField("Search notes", text: $controller.noteQuery)
                    .textFieldStyle(.roundedBorder).focused($noteSearchFocused)
                    .onSubmit
                    {
                        controller.findNote(1)
                    }
                    .accessibilityLabel("Search notes")
                Button
                {
                    controller.findNote(-1)
                } label: {
                    Label("Previous Match", systemImage: "chevron.up")
                }
                .labelStyle(.iconOnly).help("Previous note match").disabled(controller.noteMatches.isEmpty)
                Button
                {
                    controller.findNote(1)
                } label: {
                    Label("Next Match", systemImage: "chevron.down")
                }
                .labelStyle(.iconOnly).help("Next note match").disabled(controller.noteMatches.isEmpty)
            }
            if !controller.noteQuery.isEmpty
            {
                Text(controller.noteMatchLabel).font(.caption).foregroundStyle(.secondary)
            }
            NativeNotesEditor(controller: controller)
                .frame(minHeight: 120).frame(height: editorHeight)
        }
        .disabled(!controller.ready)
    }
}
