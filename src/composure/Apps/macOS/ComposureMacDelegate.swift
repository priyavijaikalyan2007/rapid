// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000107
// Created: 2026
// COMPONENT: Native Mac live coaching
// PURPOSE: Present explicit listening controls and one brief cue without transcript display or persistence.
// RELATES: MacLiveCoachComposition, LiveSessionCoordinator, MacCuePanel
// FLOW: Explicit Start -> selected audio -> private coaching -> floating cue -> Stop and clear.

import AppKit
import ComposureCore

/// Quit waits for normal cleanup. Process termination also releases native capture if Stop is unconfirmed.
@MainActor
final class ComposureMacDelegate: NSObject, NSApplicationDelegate
{
    var session: LiveSessionCoordinator?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply
    {
        guard let session, session.canStop
        else
        {
            return .terminateNow
        }
        Task
        {
            await session.stop()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
