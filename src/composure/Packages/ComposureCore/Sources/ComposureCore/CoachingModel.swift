// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 2ece4042-359a-41b9-99cf-aa41a44d8156
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Isolate the native model behind a small asynchronous contract.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

/// The core has no knowledge of framework sessions, tools, or external providers.
public protocol CoachingModel: Sendable
{
    func readiness() async -> ModelReadiness
    func prepare(_ input: MeetingPreparationInput, profile: CoachingProfile) async throws -> MeetingPreparation
}
