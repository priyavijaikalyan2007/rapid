// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: f197f898-1322-4946-959e-67744c117c37
// COMPONENT: Export source freshness
// PURPOSE: Match the renderer's canonical source before a coordinated write.
import CryptoKit
import Foundation

enum DocumentStamp
{
    static func make(_ source: String) -> String
    {
        var text = source
        if text.hasPrefix("\u{FEFF}")
        {
            text.removeFirst()
        }
        text = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\0", with: "\u{FFFD}")
        return SHA256.hash(data: Data(text.utf8)).map
        {
            String(format: "%02x", $0)
        }.joined()
    }
}
