// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 70b6a3d1-23f7-42b6-8138-dca4e0580014
// COMPONENT: Generated-section ownership
// PURPOSE: Track exact removable bytes and their source-line effect.
struct GeneratedReadingSection
{
    let id: String
    var range: Range<String.Index>
    let firstLine: Int
    let lastLine: Int
    let joinsPreviousLine: Bool
    var removedBreaks = 0
    var removedBefore = 0
}
