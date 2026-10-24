// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 1d38d112-f707-46d8-90d5-45575bfc3b26
// Created: 2026
// COMPONENT: Accepted preference state
// PURPOSE: Distinguish a valid first run from unreadable saved choices.
// RELATES: PreferencesCoordinator
// FLOW: Typed load -> accepted preferences or explicit unavailable state.

/// Only ready state carries authoritative preferences for the user interface.
public enum PreferencesState: Sendable, Equatable
{
    case ready(AppPreferences)
    case unavailable(PreferencesError)
}
