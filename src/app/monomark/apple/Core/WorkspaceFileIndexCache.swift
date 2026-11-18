// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: f6f0342c-b10d-4a4a-9ccf-b60565ad6381
// COMPONENT: Shared workspace metadata cache
// PURPOSE: Coalesce scans across document tabs and bound retained indexes and background jobs.
import Foundation

actor WorkspaceFileIndexCache
{
    static let shared = WorkspaceFileIndexCache()
    private var indexes: [URL: WorkspaceFileIndex] = [:]
    private var accessed: [URL: Int] = [:]
    private var clock = 0
    private var jobs: [URL: (UUID, Task<WorkspaceFileIndex, Error>)] = [:]
    private let scan: @Sendable (URL) throws -> WorkspaceFileIndex

    init(scan: @escaping @Sendable (URL) throws -> WorkspaceFileIndex = {
        try WorkspaceFileIndex.scan($0)
    })
    {
        self.scan = scan
    }

    func value(for folder: URL, force: Bool = false) async throws -> WorkspaceFileIndex
    {
        let root = folder.resolvingSymlinksInPath().standardizedFileURL
        if !force, let cached = indexes[root]
        {
            touch(root)
            return cached
        }
        let job = try job(for: root)
        do
        {
            let value = try await job.1.value
            if jobs[root]?.0 == job.0
            {
                jobs[root] = nil
                indexes[root] = value
                touch(root)
                trim()
            }
            return value
        }
        catch
        {
            if jobs[root]?.0 == job.0
            {
                jobs[root] = nil
            }
            throw error
        }
    }

    private func touch(_ root: URL)
    {
        clock &+= 1
        accessed[root] = clock
    }

    private func job(for root: URL) throws -> (UUID, Task<WorkspaceFileIndex, Error>)
    {
        if let job = jobs[root]
        {
            return job
        }
        guard jobs.count < 4
        else
        {
            throw ReaderFailure.unavailable
        }
        let scan = scan
        let job = (
            UUID(),
            Task.detached(priority: .utility)
            {
                try scan(root)
            }
        )
        jobs[root] = job
        return job
    }

    private func trim()
    {
        while indexes.count > 8,
              let oldest = indexes.keys.min(by: {
                  accessed[$0, default: 0] < accessed[$1, default: 0]
              })
        {
            indexes[oldest] = nil
            accessed[oldest] = nil
        }
    }
}
