// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000008
// Created: 2026
// COMPONENT: Transient live coaching
// PURPOSE: Bound private speech context and validate sparse actionable cues.
// RELATES: LiveSessionCoordinator, CueArbiter, ConversationBuffer
// FLOW: Explicit listening -> bounded context -> validated temporary cue -> Stop and clear.

import Foundation

/// One short-lived instruction. There is no historical cue collection in the UI.
public struct CoachCue: Identifiable, Sendable, Equatable
{
    public let id: UUID
    public let kind: CueKind
    public let instruction: String
    public let createdAt: Double
    public let expiresAt: Double
}
