// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000103
// Created: 2026
// COMPONENT: Native Mac live coaching
// PURPOSE: Present explicit listening controls and one brief cue without transcript display or persistence.
// RELATES: MacLiveCoachComposition, LiveSessionCoordinator, MacCuePanel
// FLOW: Explicit Start -> selected audio -> private coaching -> floating cue -> Stop and clear.

import AppKit

/// A cue or Stop control must not take keyboard focus away from the meeting application.
final class NonActivatingCuePanel: NSPanel
{
    override var canBecomeKey: Bool
    {
        false
    }

    override var canBecomeMain: Bool
    {
        false
    }
}
