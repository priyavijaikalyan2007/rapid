// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 085d5feb-63ee-48f9-a048-a2d6e375b856
// COMPONENT: Offline reading help
// PURPOSE: Keep native help topics available without a network request.
import Foundation

struct ReaderHelpTopic: Identifiable, Sendable
{
    let title: String
    let detail: String
    var id: String
    {
        title
    }
}
