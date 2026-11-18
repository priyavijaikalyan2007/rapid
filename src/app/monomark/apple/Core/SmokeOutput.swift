// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: f816e753-50d5-42c1-bce7-60d6a56b285b
// COMPONENT: Sandboxed acceptance output
// PURPOSE: Keep test PNGs in writable app-owned temporary storage while JSON travels over standard output.
import Foundation

enum SmokeOutput
{
    static func resolve(_ requested: String) -> String
    {
        guard requested == "-"
        else
        {
            return requested
        }
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("monomark-smoke-\(ProcessInfo.processInfo.processIdentifier).json").path
    }
}
