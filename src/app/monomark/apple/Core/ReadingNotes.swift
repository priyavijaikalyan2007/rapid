// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: e33d94a8-dac4-417b-9b95-c875ab2be3cb
// COMPONENT: MonoMark local annotations
// PURPOSE: Persist reading data separately from Markdown source.
// FLOW: Validated reading action -> local store -> native view.

import Foundation

/// One document's local notes and annotations are independent of its history entry.
struct ReadingNotes: Codable, Equatable, Sendable
{
    var annotations: [ReadingAnnotation] = []
    var text = ""
    var format = "markdown"
    var sourceHash: String? = nil
}
