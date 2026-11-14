// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 8c84ea83-38a2-4e08-99f9-3b2dc60cf69f
// COMPONENT: Native reading annotations
// PURPOSE: Keep highlights, comments, and notes separate from source Markdown.
// FLOW: Native action -> ordered local persistence -> reader decoration.

import Foundation

extension ReaderSession
{
    func receiveSelection(_ message: [String: Any])
    {
        annotations.selection = []
        guard let value = message["anchors"] as? [[String: Any]], value.count <= 128,
              let data = try? JSONSerialization.data(withJSONObject: value), data.count <= 1024 * 1024,
              let anchors = try? JSONDecoder().decode([TextAnchor].self, from: data)
        else
        {
            return
        }
        if anchors.isEmpty
        {
            annotations.selection = []
            return
        }
        guard (try? ReadingAnnotation(anchors: anchors).validate()) != nil
        else
        {
            return
        }
        annotations.selection = anchors
    }

    func sendAnnotations()
    {
        command(["type": "annotations", "value": annotations.records.map(dictionary)])
    }

    func navigateAnnotation(_ annotation: ReadingAnnotation)
    {
        command(["type": "annotation", "id": annotation.id])
    }
}
