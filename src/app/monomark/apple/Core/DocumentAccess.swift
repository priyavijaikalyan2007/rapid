// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: cf503f4f-d78f-4444-a471-b9643a43b324
// Created: 2026
// COMPONENT: MonoMark core
// PURPOSE: Enforce bounded, coordinated reads and resolved path scope.
// RELATES: MonoMarkCoreTests
// FLOW: Validated input -> local processing -> typed result.

import Foundation
import CryptoKit

/// Bounded file access and stable filesystem identity. Mutable files use reads rather than unsafe long-lived mappings.
enum DocumentAccess
{
    static let sourceLimit = 100 * 1024 * 1024

    static func contains(_ file: URL, in root: URL) -> Bool
    {
        let parent = root.resolvingSymlinksInPath().standardizedFileURL.path
        let child = file.resolvingSymlinksInPath().standardizedFileURL.path
        return child == parent || child.hasPrefix(parent.hasSuffix("/") ? parent : parent + "/")
    }

    static func identity(_ file: URL) throws -> String
    {
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        let volume = String(describing: attributes[.systemNumber] ?? file.path)
        let inode = String(describing: attributes[.systemFileNumber] ?? file.path)
        let created = String(describing: attributes[.creationDate] ?? "")
        let bytes = Data("\(volume):\(inode):\(created)".utf8)
        return SHA256.hash(data: bytes).map
        {
            String(format: "%02x", $0)
        }.joined()
    }

    /// Coordinate with file providers and reject oversized input before and during reading.
    static func read(_ file: URL, limit: Int = sourceLimit) throws -> Data
    {
        var coordinationError: NSError?
        var result: Result<Data, Error> = .failure(ReaderFailure.unavailable)
        NSFileCoordinator().coordinate(readingItemAt: file, options: .withoutChanges, error: &coordinationError)
        { url in
            result = Result
            {
                try boundedRead(url, limit: limit)
            }
        }
        if let coordinationError
        {
            throw coordinationError
        }
        return try result.get()
    }

    /// Read bytes and filesystem identity inside the same provider coordination boundary.
    static func snapshot(_ file: URL, limit: Int = sourceLimit) throws -> (data: Data, identity: String)
    {
        var error: NSError?
        var result: Result<(Data, String), Error> = .failure(ReaderFailure.unavailable)
        NSFileCoordinator().coordinate(readingItemAt: file, options: .withoutChanges, error: &error)
        { url in
            result = Result
            {
                (try boundedRead(url, limit: limit), try identity(url))
            }
        }
        if let error
        {
            throw error
        }
        return try result.get()
    }

    static func boundedRead(_ file: URL, limit: Int) throws -> Data
    {
        let size = try file.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard size.isRegularFile == true
        else
        {
            throw ReaderFailure.unavailable
        }
        guard (size.fileSize ?? Int.max) <= limit
        else
        {
            throw ReaderFailure.oversized
        }
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        var data = Data()
        while let part = try handle.read(upToCount: min(256 * 1024, limit - data.count + 1)), !part.isEmpty
        {
            data.append(part)
            if data.count > limit
            {
                throw ReaderFailure.oversized
            }
        }
        guard String(data: data, encoding: .utf8) != nil
        else
        {
            throw ReaderFailure.invalidEncoding
        }
        return data
    }

    /// A preview prefix never reads the complete document or causes an implicit provider download.
    static func prefix(_ file: URL, limit: Int = 16384) throws -> String
    {
        let values = try file.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
        if values.isUbiquitousItem == true && values.ubiquitousItemDownloadingStatus == .notDownloaded
        {
            throw ReaderFailure.unavailable
        }
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        return String(decoding: try handle.read(upToCount: limit) ?? Data(), as: UTF8.self)
    }
}
