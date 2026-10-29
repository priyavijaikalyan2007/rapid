// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000009
// Created: 2026
// COMPONENT: Transient live coaching
// PURPOSE: Bound private speech context and validate sparse actionable cues.
// RELATES: LiveSessionCoordinator, CueArbiter, ConversationBuffer
// FLOW: Explicit listening -> bounded context -> validated temporary cue -> Stop and clear.

/// Centralizes tunable timing. Every profile retains a strong bias toward silence.
public struct CuePolicy: Sendable
{
    public static let displaySeconds = 8.0
    public static let repeatSeconds = 90.0
    public static let maximumEvidenceAge = 12.0
    public let cooldownSeconds: Double
    public let maximumInTenMinutes: Int

    public init(profile: CoachingProfile)
    {
        switch profile.cueFrequency
        {
        case .low:
            cooldownSeconds = 45
            maximumInTenMinutes = 2
        case .normal:
            cooldownSeconds = 20
            maximumInTenMinutes = 4
        case .high:
            cooldownSeconds = 12
            maximumInTenMinutes = 6
        }
    }
}
