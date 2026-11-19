// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 2d6424f1-d1f2-48aa-a2a6-cd177b42f90d
// COMPONENT: Local document event contracts
// PURPOSE: Verify file writes, atomic replacements, and observer cleanup without polling in the app.
import Foundation
import Testing
@testable import MonoMarkCore

@MainActor struct DocumentWatcherTests
{
    private func fixture() throws -> URL
    {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("Reading.md")
        try Data("First".utf8).write(to: file)
        return file
    }

    private func waitUntil(_ condition: () -> Bool) async throws
    {
        for _ in 0 ..< 40
        {
            if condition()
            {
                return
            }
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    @Test func directWritesRefreshTheObservedDocument() async throws
    {
        let file = try fixture()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        var changes = 0
        let watcher = DocumentWatcher(file: file)
        {
            changes += 1
        }
        defer { watcher.cancel() }
        try Data("Second".utf8).write(to: file)
        try await waitUntil
        {
            changes == 1
        }
        #expect(changes == 1)
    }

    @Test func atomicReplacementsRearmTheNewFile() async throws
    {
        let file = try fixture()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        var changes = 0
        let watcher = DocumentWatcher(file: file)
        {
            changes += 1
        }
        defer { watcher.cancel() }
        try Data("Second".utf8).write(to: file, options: .atomic)
        try await waitUntil
        {
            changes == 1
        }
        try Data("Third".utf8).write(to: file)
        try await waitUntil
        {
            changes == 2
        }
        #expect(changes == 2)
    }

    @Test func unrelatedDirectoryWritesDoNotRefreshTheDocument() async throws
    {
        let file = try fixture()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        var changes = 0
        let watcher = DocumentWatcher(file: file)
        {
            changes += 1
        }
        defer { watcher.cancel() }
        try Data("Other".utf8).write(to: file.deletingLastPathComponent().appendingPathComponent("Other.md"))
        try await Task.sleep(for: .milliseconds(450))
        #expect(changes == 0)
    }

    @Test func cancellationPreventsPendingAndFutureRefreshes() async throws
    {
        let file = try fixture()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        var changes = 0
        let watcher = DocumentWatcher(file: file)
        {
            changes += 1
        }
        try Data("Second".utf8).write(to: file)
        watcher.cancel()
        try Data("Third".utf8).write(to: file, options: .atomic)
        try await Task.sleep(for: .milliseconds(450))
        #expect(changes == 0)
    }

    @Test func metadataOnlyChangesDoNotRefreshTheDocument() async throws
    {
        let file = try fixture()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        var changes = 0
        let watcher = DocumentWatcher(file: file)
        {
            changes += 1
        }
        defer { watcher.cancel() }
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        let permissions = try #require(attributes[.posixPermissions] as? NSNumber).intValue

        try FileManager.default.setAttributes([.posixPermissions: permissions ^ 4], ofItemAtPath: file.path)
        try await Task.sleep(for: .milliseconds(500))

        #expect(changes == 0)
    }

    @Test func sameSizeWritesWithRestoredDatesStillRefresh() async throws
    {
        let file = try fixture()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        var changes = 0
        let watcher = DocumentWatcher(file: file)
        {
            changes += 1
        }
        defer { watcher.cancel() }
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        let modified = try #require(attributes[.modificationDate] as? Date)

        try Data("Third".utf8).write(to: file)
        try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: file.path)
        try await waitUntil
        {
            changes == 1
        }

        #expect(changes == 1)
    }

    @Test func lossOfReadPermissionStillRefreshes() async throws
    {
        let file = try fixture()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        var changes = 0
        let watcher = DocumentWatcher(file: file)
        {
            changes += 1
        }
        defer { watcher.cancel() }

        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: file.path)
        try await waitUntil
        {
            changes == 1
        }

        #expect(changes == 1)
    }
}
