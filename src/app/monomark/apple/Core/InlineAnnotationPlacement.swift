// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 70b6a3d1-23f7-42b6-8138-dca4e0580018
// COMPONENT: Inline export planning
// PURPOSE: Keep annotation order and complete-block insertion boundaries explicit.
struct InlineAnnotationPlacement
{
    var annotation: ReadingAnnotation
    let index: Int
    let endLine: Int
    let addedLines: Int
}
