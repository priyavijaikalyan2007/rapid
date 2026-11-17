// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 3a08690a-dad5-4225-96ac-2eadcd93c52d
// COMPONENT: Local document observation
// PURPOSE: Distinguish target changes from unrelated directory writes.
import Foundation

struct FileFingerprint: Equatable
{
    let modified: Date?
    let bytes: UInt64?
    let inode: UInt64?

    static func read(_ file: URL) -> FileFingerprint?
    {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: file.path)
        else
        {
            return nil
        }
        return FileFingerprint(
            modified: attributes[.modificationDate] as? Date,
            bytes: (attributes[.size] as? NSNumber)?.uint64Value,
            inode: (attributes[.systemFileNumber] as? NSNumber)?.uint64Value
        )
    }
}
