// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 70b6a3d1-23f7-42b6-8138-dca4e0580013
// COMPONENT: Generated-section scanning
// PURPOSE: Keep literal marker text inside code fences outside export ownership.
struct MarkdownFence
{
    private var character: Character?
    private var length = 0
    var isOpen: Bool
    {
        character != nil
    }

    mutating func consume(_ line: String) -> Bool
    {
        let stripped = line.drop(while: {
            $0 == " "
        })
        guard line.count - stripped.count <= 3, let first = stripped.first, first == "`" || first == "~"
        else
        {
            return isOpen
        }
        let count = stripped.prefix(while: {
            $0 == first
        }).count
        if let active = character
        {
            if first == active, count >= length, stripped.dropFirst(count).allSatisfy(\.isWhitespace)
            {
                character = nil
            }
            return true
        }
        guard count >= 3
        else
        {
            return false
        }
        character = first
        length = count
        return true
    }
}
