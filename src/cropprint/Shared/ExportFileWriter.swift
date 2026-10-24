// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 49124da3-4ede-4702-b14c-6105ea5f691e
// Created: 2026
// COMPONENT: Export file publication
// PURPOSE: Publish complete export files without overwriting another file.
// RELATES: ImageExporter, ExportFileWriterTests
// FLOW: Private staging file -> exclusive publication -> owned-file rollback on failure.
// SECURITY: Never remove a destination whose identity differs from the file this operation created.

import Darwin
import Foundation

/// Writes export groups and rolls back only files created by the current operation.
enum ExportFileWriter
{
    /// Device and inode values identify a file without relying on a reusable path.
    private typealias PublishedFile = (url: URL, device: dev_t, inode: ino_t)

    /// Recoverable errors owned by this file-publication contract.
    enum Failure: LocalizedError
    {
        case invalidDestination
        case incompleteCleanup

        var errorDescription: String?
        {
            switch self
            {
            case .invalidDestination:
                "The export destination is not a local file. Choose a local folder and try again."
            case .incompleteCleanup:
                "The export did not complete. Check the output folder for partial files before trying again."
            }
        }
    }

    /// Publishes each completed file exclusively and preserves preexisting destinations.
    static func write(_ outputs: [(data: Data, url: URL)]) throws
    {
        var published: [PublishedFile] = []
        do
        {
            for output in outputs
            {
                published.append(try publish(output.data, to: output.url))
            }
        }
        catch
        {
            var cleanupComplete = true
            for file in published
            {
                cleanupComplete = removeIfOwned(file) && cleanupComplete
            }
            guard cleanupComplete
            else
            {
                throw Failure.incompleteCleanup
            }
            throw error
        }
    }

    /// Stages bytes in a private file before an exclusive rename on a supporting local filesystem.
    private static func publish(_ data: Data, to destination: URL) throws -> PublishedFile
    {
        guard destination.isFileURL
        else
        {
            throw Failure.invalidDestination
        }
        let (descriptor, path) = try stagingFile(for: destination)
        defer
        { _ = Darwin.close(descriptor)
            _ = Darwin.unlink(path)
        }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        try handle.write(contentsOf: data)
        try handle.synchronize()
        var identity = stat()
        guard fstat(descriptor, &identity) == 0
        else
        {
            throw posixFailure()
        }
        guard Darwin.renamex_np(path, destination.path, UInt32(RENAME_EXCL)) == 0
        else
        {
            throw posixFailure()
        }
        return (destination, identity.st_dev, identity.st_ino)
    }

    /// Removes an output only when it still names the exact file that this operation published.
    private static func removeIfOwned(_ file: PublishedFile) -> Bool
    {
        var current = stat()
        guard lstat(file.url.path, &current) == 0
        else
        {
            return errno == ENOENT
        }
        guard current.st_dev == file.device, current.st_ino == file.inode
        else
        {
            return true
        }
        return Darwin.unlink(file.url.path) == 0 || errno == ENOENT
    }

    /// Preserves the operating-system error code without placing user paths in diagnostic text.
    private static func posixFailure() -> POSIXError
    {
        POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }

    /// Creates a private staging file beside the destination so publication remains on one filesystem.
    private static func stagingFile(for destination: URL) throws -> (Int32, String)
    {
        var template = Array(destination.deletingLastPathComponent().appendingPathComponent(
            ".cropprint-export-XXXXXX"
        ).path.utf8CString)
        let descriptor = mkstemp(&template)
        guard descriptor >= 0
        else
        {
            throw posixFailure()
        }
        let path = String(
            decoding: template.dropLast().map
            {
                UInt8(bitPattern: $0)
            },
            as: UTF8.self
        )
        return (descriptor, path)
    }
}
