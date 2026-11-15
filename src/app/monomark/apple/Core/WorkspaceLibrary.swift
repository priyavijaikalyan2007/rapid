// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: cfc2f65d-3b97-4091-9bfe-4e9088c4d5c6
// COMPONENT: Shared recent-workspace list
// PURPOSE: Publish one bounded workspace list across document windows while SQLite retains all records.
import Foundation
import Combine

@MainActor final class WorkspaceLibrary: ObservableObject
{
    static let shared = WorkspaceLibrary()
    @Published private(set) var records: [WorkspaceRecord] = []
    @Published private(set) var error: String?
    private let store: WorkspaceStore?

    init(databaseURL: URL? = nil)
    {
        let testing = ProcessInfo.processInfo.arguments.contains("--demo") ||
            ProcessInfo.processInfo.arguments.contains("--smoke-test")
        let base = testing ? FileManager.default.temporaryDirectory
            .appendingPathComponent("monomark-workspaces-\(UUID())") :
            URL.applicationSupportDirectory.appendingPathComponent("MonoMark")
        do
        {
            store = try WorkspaceStore(url: databaseURL ?? base.appendingPathComponent("workspaces.sqlite"))
        }
        catch
        {
            store = nil
            self.error = error.localizedDescription
        }
    }

    func refresh() async
    {
        guard let store
        else
        {
            return
        }
        do
        {
            records = try await store.recent()
            error = nil
        }
        catch
        {
            self.error = error.localizedDescription
        }
    }

    func remember(_ record: WorkspaceRecord) async
    {
        guard let store
        else
        {
            return
        }
        do
        {
            try await store.remember(record)
            await refresh()
        }
        catch
        {
            self.error = error.localizedDescription
        }
    }

    func forget(_ record: WorkspaceRecord) async
    {
        guard let store
        else
        {
            return
        }
        do
        {
            try await store.remove(record.id)
            await refresh()
        }
        catch
        {
            self.error = error.localizedDescription
        }
    }
}
