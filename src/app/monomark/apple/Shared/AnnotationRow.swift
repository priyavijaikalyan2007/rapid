// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 2ab615d9-cd45-4f84-8bda-a3d111d7ac43
// COMPONENT: Native reading annotations
// PURPOSE: Keep highlights, comments, and notes separate from source Markdown.
// FLOW: Native action -> ordered local persistence -> reader decoration.

import SwiftUI

/// Each quoted highlight has independent color, comment, and navigation controls.
struct AnnotationRow: View
{
    let annotation: ReadingAnnotation
    var attached: Bool
    var update: (ReadingAnnotation) -> Void
    var remove: (ReadingAnnotation) -> Void
    var navigate: () -> Void

    var body: some View
    {
        VStack(alignment: .leading, spacing: 8)
        {
            Button(action: navigate)
            {
                Text(annotation.anchors.map(\.quote).joined(separator: "\n"))
                    .multilineTextAlignment(.leading).lineLimit(8)
            }.buttonStyle(.plain).help("Jump to this quotation")
            if !attached
            {
                Text("Not attached in the current view. Locate the quotation to check its source.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Picker("Color", selection: Binding(get: {
                annotation.color
            }, set: { value in
                var changed = annotation
                changed.color = value
                update(changed)
            }))
            {
                ForEach(ReadingAnnotation.colors, id: \.self)
                {
                    Text($0.capitalized).tag($0)
                }
            }
            TextField("Add a comment", text: Binding(get: {
                annotation.comment
            }, set: { value in
                var changed = annotation
                changed.comment = value
                update(changed)
            }), axis: .vertical).lineLimit(2 ... 8)
            HStack
            {
                Spacer()
                Button(role: .destructive)
                {
                    remove(annotation)
                } label: {
                    Image(systemName: "trash")
                }
                .help("Delete annotation").accessibilityLabel("Delete annotation")
            }
            Divider()
        }
        .padding(6)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
    }
}
