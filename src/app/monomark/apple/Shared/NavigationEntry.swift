// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 7e243e6a-daff-4e27-8222-449a70985b4d
// Created: 2026
// COMPONENT: MonoMark native UI
// PURPOSE: Model heading and object navigation in the native sidebar.
// RELATES: MonoMark product and implementation specifications
// FLOW: Native command -> session -> validated renderer bridge.

import Foundation

/// Navigation indexes come from the same parse that produces visible document blocks.
struct NavigationEntry: Identifiable, Decodable
{
    var id: String
    var title: String
    var kind: String
    var level: Int
    var parent: String?
    var blockID: String
}
