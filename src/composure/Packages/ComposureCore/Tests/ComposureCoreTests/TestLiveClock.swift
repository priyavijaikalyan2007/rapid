// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000007
// Created: 2026
// COMPONENT: Deterministic live-session test clock
// PURPOSE: Advance synthetic session timing without waiting through native cue cooldowns.
// RELATES: LiveSessionCoordinatorTests
// FLOW: Test-controlled monotonic time -> session expiry, scheduling, and suppression.

@MainActor
final class TestLiveClock
{
    var now = 100.0
}
