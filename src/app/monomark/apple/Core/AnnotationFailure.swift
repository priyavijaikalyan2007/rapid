// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: f6013a25-9c59-4d35-b849-883790c2646f
// COMPONENT: MonoMark local annotations
// PURPOSE: Persist reading data separately from Markdown source.
// FLOW: Validated reading action -> local store -> native view.

import Foundation

/// Errors preserve local drafts and explain the recovery action.
enum AnnotationFailure: Error, LocalizedError
{
    case invalidData
    case notesConflict
    case unsupportedVersion
    case invalidMarkers

    var errorDescription: String?
    {
        switch self
        {
        case .invalidData: "These notes exceed the supported size or contain an invalid annotation. Shorten the selection or note."
        case .notesConflict: "Another window changed these notes. Your draft remains visible. Copy it before reloading the saved notes."
        case .unsupportedVersion: "A newer MonoMark version created this notes database. Use that version to open your notes."
        case .invalidMarkers: "The generated-section markers are incomplete or repeated. Repair the markers or export a copy."
        }
    }
}
