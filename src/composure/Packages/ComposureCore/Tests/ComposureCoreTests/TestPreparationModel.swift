// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f27b3a81-a286-495c-868c-2fcf79df6f48
// Created: 2026
// COMPONENT: Preparation regression tests
// PURPOSE: Verify bounded, transient coaching without real conversation content.
// RELATES: PreparationService, MeetingPreparation
// FLOW: Synthetic input -> preparation contract -> bounded result or controlled failure.

import Foundation
@testable import ComposureCore

actor TestPreparationModel: CoachingModel
{
    let status: ModelReadiness
    let failure: PreparationError?
    let delay: Duration
    private(set) var calls = 0
    init(status: ModelReadiness = .available, failure: PreparationError? = nil, delay: Duration = .zero)
    {
        self.status = status
        self.failure = failure
        self.delay = delay
    }

    func readiness() async -> ModelReadiness
    {
        status
    }

    func prepare(_ input: MeetingPreparationInput, profile: CoachingProfile) async throws -> MeetingPreparation
    {
        calls += 1
        try await Task.sleep(for: delay)
        if let failure
        {
            throw failure
        }
        return try FallbackPreparation.make(input: input, profile: profile)
    }
}
