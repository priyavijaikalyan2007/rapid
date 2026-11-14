// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: d140b60a-7527-4f15-918c-edbe158a28ae
// Created: 2026
// COMPONENT: MonoMark native UI
// PURPOSE: Represent a document link occurrence for native navigation.
// RELATES: MonoMark product and implementation specifications
// FLOW: Native command -> session -> validated renderer bridge.

import Foundation

/// Each occurrence retains its source block instead of losing repeated link locations.
struct DocumentLink: Identifiable, Decodable
{
    var href: String
    var title: String
    var kind: String
    var blockID: String
    var id: String
    {
        blockID + href + title
    }
}
