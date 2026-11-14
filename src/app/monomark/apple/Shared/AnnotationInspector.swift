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
    @State private var tab = "Annotations"
    @State private var discard = false

    var body: some View
    {
        VStack(alignment: .leading, spacing: 12)
        {
            Picker("Reading data", selection: $tab)
            {
                Text("Annotations").tag("Annotations")
                Text("Notes").tag("Notes")
            }.pickerStyle(.segmented)
            if tab == "Annotations"
            {
                annotations
            }
            else
            {
                notes
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
        .padding()
        .disabled(!controller.ready && controller.error == nil)
        .confirmationDialog("Discard the visible draft and reload saved notes?", isPresented: $discard)
        {
            Button("Discard Draft", role: .destructive)
            {
                controller.reload()
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
            ScrollViewReader
            { proxy in
                ScrollView
                {
                    LazyVStack(alignment: .leading, spacing: 16)
                    {
                        ForEach(controller.records)
                        { annotation in
                            AnnotationRow(
                                annotation: annotation,
                                attached: controller.visibleIDs.contains(annotation.id),
                                update: controller.update,
                                remove: controller.remove
                            )
                            {
                                if let anchor = annotation.anchors.first
                                {
                                    session.command(["type": "find", "query": anchor.quote])
                                }
                            }.id(annotation.id)
                        }
                    }
                }
                .onChange(of: controller.selectedID)
                { _, id in
                    if let id
                    {
                        proxy.scrollTo(id)
                    }
                }
            }
        }
    }

    private var notes: some View
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
            TextEditor(text: Binding(get: {
                controller.text
            }, set: {
                controller.editNotes($0)
            }))
            .font(.system(.body, design: .monospaced))
            .accessibilityLabel("Reading notes")
            .accessibilityIdentifier("reading-notes")
        }
    }
}
