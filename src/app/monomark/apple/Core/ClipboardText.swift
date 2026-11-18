// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 20e97ae6-1a64-4aaa-bd44-d2c449d95685
// COMPONENT: Native clipboard boundary
// PURPOSE: Bound explicit full-document copy using UTF-8 bytes rather than character count.
import Foundation

enum ClipboardText
{
    // Matches the worker selection-copy budget, with room for a full supported source document.
    static let byteLimit = 128 * 1024 * 1024

    static func accepts(_ text: String, byteLimit: Int = byteLimit) -> Bool
    {
        byteLimit >= 0 && text.utf8.count <= byteLimit
    }
}
