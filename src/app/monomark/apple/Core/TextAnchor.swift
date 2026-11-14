// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 7621bc14-311a-424e-bc09-7dff49b725ff
// COMPONENT: MonoMark local annotations
// PURPOSE: Persist reading data separately from Markdown source.
// FLOW: Validated reading action -> local store -> native view.

import Foundation

/// Quote context permits conservative attachment after nearby source text changes.
struct TextAnchor: Codable, Equatable, Sendable
{
    var blockID: String
    var quote: String
    var prefix: String
    var suffix: String
    var start: Int
}
