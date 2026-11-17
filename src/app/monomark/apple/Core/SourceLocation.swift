// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 02067ab6-c7b9-4997-bc4e-3a96f380c7bb
// COMPONENT: Reading source references
// PURPOSE: Identify a complete source block without pretending to map rendered wrapping.
import Foundation

struct SourceLocation: Codable, Equatable, Hashable, Sendable
{
    var line: Int
    var endLine: Int
    var section: String

    var isValid: Bool
    {
        line > 0 && endLine >= line && endLine <= 104857601 && section.count <= 512
    }
}
