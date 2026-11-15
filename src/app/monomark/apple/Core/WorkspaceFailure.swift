// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 209ca4d0-d00a-43d9-8034-9c2c04ba72cf
// COMPONENT: Workspace recovery errors
// PURPOSE: Explain metadata failures without discarding folders or reading notes.
import Foundation

enum WorkspaceFailure: LocalizedError
{
    case invalidRecord, unsupportedVersion

    var errorDescription: String?
    {
        switch self
        {
        case .invalidRecord: "The workspace could not be saved. Open its folder again to renew access."
        case .unsupportedVersion: "A newer MonoMark version created these workspaces. Update MonoMark to open them."
        }
    }
}
