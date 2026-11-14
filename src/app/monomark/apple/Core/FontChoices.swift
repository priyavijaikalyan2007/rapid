// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 72ea7555-2767-49ad-940a-338da6c62ec9
// COMPONENT: Installed font selection
// PURPOSE: Retain installed and saved family names without a fixed product font list.
import Foundation

enum FontChoices
{
    static func make(installed: [String], current: String) -> [String]
    {
        var names = Set(installed.filter
        {
            !$0.isEmpty && $0 != "ui-monospace"
        })
        if !current.isEmpty && current != "ui-monospace"
        {
            names.insert(current)
        }
        return names.sorted
        {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }
}
