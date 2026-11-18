// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 878a13e7-46ec-441e-903b-416f5ca92da4
// COMPONENT: Workspace reference indexing contracts
// PURPOSE: Bound metadata scans and exclude hidden files and symlink escapes.
import Foundation
import Testing
import os
@testable import MonoMarkCore

struct WorkspaceFileIndexTests
{
    private func fixture() throws -> URL
    {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("docs"),
            withIntermediateDirectories: true
        )
        try Data("# A".utf8).write(to: root.appendingPathComponent("A.md"))
        try Data("# B".utf8).write(to: root.appendingPathComponent("docs/B.markdown"))
        try Data("hidden".utf8).write(to: root.appendingPathComponent(".Hidden.md"))
        try Data("text".utf8).write(to: root.appendingPathComponent("Ignore.txt"))
        return root
    }

    @Test func scansOnlyVisibleMarkdownAndRejectsSymlinkEscapes() throws
    {
        let root = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createSymbolicLink(
            at: root.appendingPathComponent("escape"),
            withDestinationURL: root.deletingLastPathComponent()
        )
        let index = try WorkspaceFileIndex.scan(root)
        #expect(index.paths == ["A.md", "docs/B.markdown"])
        #expect(index.relativePath(for: root.appendingPathComponent("docs/B.markdown")) == "docs/B.markdown")
        #expect(index.relativePath(for: root.deletingLastPathComponent().appendingPathComponent("outside.md")) == nil)
    }

    @Test func limitsStopEnumeration() throws
    {
        let root = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let index = try WorkspaceFileIndex.scan(root, entryLimit: 1, fileLimit: 1)
        #expect(index.truncated)
        #expect(index.paths.count <= 1)
    }

    @Test func sharedCacheCoalescesRequestsAndCanBeRefreshed() async throws
    {
        let count = OSAllocatedUnfairLock(initialState: 0)
        let root = URL(fileURLWithPath: "/synthetic-workspace")
        let cache = WorkspaceFileIndexCache
        { root in
            count.withLock
            {
                $0 += 1
            }
            Thread.sleep(forTimeInterval: 0.03)
            return WorkspaceFileIndex(root: root, paths: ["A.md"])
        }
        async let first = cache.value(for: root)
        async let second = cache.value(for: root)
        _ = try await (first, second)
        #expect(count.withLock
        {
            $0
        } == 1)
        _ = try await cache.value(for: root, force: true)
        #expect(count.withLock
        {
            $0
        } == 2)
    }
}
