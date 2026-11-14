// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 4c6d04f5-6846-4934-bf62-9c976380b6e9
// COMPONENT: Active document presentation
// PURPOSE: Keep paths, file selection, and folder disclosure consistent.
import Foundation

enum DocumentPresentation
{
    static func isSelected(_ current: URL?, file: URL) -> Bool
    {
        current?.standardizedFileURL.resolvingSymlinksInPath() == file.standardizedFileURL.resolvingSymlinksInPath()
    }

    static func title(_ file: URL) -> String
    {
        file.path
    }

    static func reveals(_ folder: URL, document: URL?) -> Bool
    {
        guard let document
        else
        {
            return false
        }
        return folder != document && DocumentAccess.contains(document, in: folder)
    }
}
