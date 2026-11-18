// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 6ecf61fa-3ec5-43ba-a4ec-81618a6242d9
// Created: 2026
// COMPONENT: MonoMark core
// PURPOSE: Persist only document identity, access references, and reading metadata.
// RELATES: MonoMarkCoreTests
// FLOW: Validated input -> local processing -> typed result.

import Foundation

/// Small durable metadata. Document contents and preview excerpts are deliberately absent.
struct ReadingState: Codable, Equatable, Identifiable, Sendable
{
    var id: String
    var path: String
    var accessedAt: Double
    var updatedAt: Double? = nil
    var anchor = ""
    var offset = 0.0
    var progress = 0.0
    var zoom = 1.0
    var preferences: ReaderPreferences?
    var rootPath: String?
    var bookmark: Data?
    var rootBookmark: Data?
    var title: String
    {
        URL(fileURLWithPath: path).lastPathComponent
    }
}
