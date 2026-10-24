// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 3347b956-5ee6-4ffd-acc9-9f6b850fca82
// Created: 2026
// COMPONENT: macos-window-info
// PURPOSE: Report geometry for the requested application window without reading user content.
// RELATES: PROJECT.md, instructions/WORKFLOW.md
// FLOW: Authored source -> component validation -> local result.

import CoreGraphics
import Foundation

/// Prints only the geometry of the requested capture window, without reading screen pixels.
@main
struct WindowInfo
{
    /// Preserves the capture helper exit contract while explaining invalid arguments.
    static func main()
    {
        guard CommandLine.arguments.count == 2
        else
        {
            try? FileHandle.standardError.write(contentsOf: Data("Usage: window-info APPLICATION_NAME\n".utf8))
            exit(2)
        }
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]],
              let information = windows.compactMap({
                  geometry($0, owner: CommandLine.arguments[1])
              }).first
        else
        {
            exit(1)
        }
        print(information)
    }

    /// Selects the normal application window large enough for the authored screenshot layout.
    private static func geometry(_ window: [String: Any], owner: String) -> String?
    {
        guard window[kCGWindowOwnerName as String] as? String == owner,
              window[kCGWindowLayer as String] as? Int == 0,
              let number = window[kCGWindowNumber as String] as? Int,
              let dictionary = window[kCGWindowBounds as String] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: dictionary as CFDictionary), bounds.width >= 1000
        else
        {
            return nil
        }
        return "\(number) \(Int(bounds.minX)) \(Int(bounds.minY)) \(Int(bounds.width)) \(Int(bounds.height))"
    }
}
