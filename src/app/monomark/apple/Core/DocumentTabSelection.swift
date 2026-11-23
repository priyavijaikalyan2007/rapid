// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 4d02ba15-2dc7-4353-a1d4-b0d3d891d9ae
// COMPONENT: Stable document tab selection
// PURPOSE: Keep selection independent of array offsets during asynchronous document closure.
// FLOW: Document identities -> ordered selection -> surviving active document.
import Foundation

struct DocumentTabSelection
{
    private(set) var ids: [UUID]
    private(set) var selectedID: UUID

    init(first: UUID)
    {
        ids = [first]
        selectedID = first
    }

    mutating func append(_ id: UUID)
    {
        if !ids.contains(id)
        {
            ids.append(id)
        }
        selectedID = id
    }

    @discardableResult mutating func select(_ id: UUID) -> Bool
    {
        guard ids.contains(id)
        else
        {
            return false
        }
        selectedID = id
        return true
    }

    @discardableResult mutating func remove(_ id: UUID) -> Bool
    {
        guard ids.count > 1, let index = ids.firstIndex(of: id)
        else
        {
            return false
        }
        ids.remove(at: index)
        if selectedID == id
        {
            selectedID = ids[min(index, ids.count - 1)]
        }
        return true
    }
}
