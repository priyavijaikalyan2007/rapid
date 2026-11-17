// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 994698b2-3a64-44bf-b541-b24de6929a15
// COMPONENT: MonoMark local annotations
// PURPOSE: Persist reading data separately from Markdown source.
// FLOW: Validated reading action -> local store -> native view.

import Foundation

/// An annotation belongs to the application, never to the Markdown source.
struct ReadingAnnotation: Codable, Equatable, Identifiable, Sendable
{
    var id = UUID().uuidString
    var anchors: [TextAnchor]
    var color = "yellow"
    var comment = ""
    var createdAt = Date().timeIntervalSince1970
    var updatedAt: Double?

    func validate() throws
    {
        guard UUID(uuidString: id) != nil, Self.colors.contains(color), createdAt.isFinite,
              (updatedAt ?? createdAt).isFinite,
              !anchors.isEmpty, anchors.count <= 128, comment.utf8.count <= 65536,
              anchors.allSatisfy({ !$0.quote.isEmpty && $0.quote.utf8.count <= 65536 &&
                      $0.prefix.count <= 64 && $0.suffix.count <= 64 && $0.blockID.count <= 512 && $0.start >= 0 &&
                      ($0.location?.isValid ?? true) })
        else
        {
            throw AnnotationFailure.invalidData
        }
    }

    static let colors = ["yellow", "green", "blue", "pink", "purple"]
}
