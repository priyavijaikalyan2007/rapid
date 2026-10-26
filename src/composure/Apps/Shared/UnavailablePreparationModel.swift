// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: e167a6bc-fdb8-4217-9148-cddd7627a51d
// Created: 2026
// COMPONENT: Native conversation preparation
// PURPOSE: Force the unavailable-model test path without changing system Apple Intelligence settings.
// RELATES: PreparationCoordinator, PreparationService
// FLOW: Native controls -> bounded transient preparation -> explicit clear or lifecycle cleanup.

#if DEBUG
import ComposureCore

/// Selected only by explicit isolated UI-test arguments, never by Release composition.
struct UnavailablePreparationModel: CoachingModel
{
    func readiness() async -> ModelReadiness
    {
        .deviceNotEligible
    }

    func prepare(_: MeetingPreparationInput, profile _: CoachingProfile) async throws -> MeetingPreparation
    {
        throw PreparationError.generationFailed
    }
}
#endif
