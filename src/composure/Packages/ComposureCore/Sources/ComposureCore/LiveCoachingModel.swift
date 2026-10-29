// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000031
// Created: 2026
// COMPONENT: Live session coordination
// PURPOSE: Keep capture and coaching bounded, explicit, and transient across native lifecycle changes.
// RELATES: LiveSessionCoordinator, LiveTranscriptionSource, LiveCoachingModel
// FLOW: Explicit Start -> bounded private processing -> sparse cue -> Stop and clear.

/// A nil result is the normal decision to remain silent. Implementations must honor cancellation.
public protocol LiveCoachingModel: Sendable
{
    func readiness() async -> ModelReadiness
    func evaluate(_ input: LiveCoachingInput) async throws -> CueProposal?
}
