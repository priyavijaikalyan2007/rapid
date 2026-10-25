// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 7afb88ea-ed6e-408b-99a1-ab57a23ab651
// Created: 2026
// COMPONENT: Preparation regression tests
// PURPOSE: Verify bounded, transient coaching without real conversation content.
// RELATES: PreparationService, MeetingPreparation
// FLOW: Synthetic input -> preparation contract -> bounded result or controlled failure.

import Testing
@testable import ComposureCore

@MainActor
struct PreparationCoordinatorTests
{
    @Test func preparationDoesNotRestoreOnNewCoordinator() async
    {
        let first = makeCoordinator()
        first.topic = "Synthetic discussion"
        await first.prepare(profile: CoachingProfile())
        #expect(makeCoordinator().topic.isEmpty && makeCoordinator().result == nil)
    }

    @Test func clearDropsInputsAndOutput() async
    {
        let coordinator = makeCoordinator()
        coordinator.topic = "Synthetic discussion"
        await coordinator.prepare(profile: CoachingProfile())
        coordinator.clear()
        #expect(coordinator.topic.isEmpty && coordinator.result == nil)
    }

    @Test func invalidInputDoesNotStartGeneration() async
    {
        let coordinator = makeCoordinator()
        await coordinator.prepare(profile: CoachingProfile())
        #expect(coordinator.error == .topicRequired)
    }

    @Test func clearInvalidatesInFlightResult() async
    {
        let model = TestPreparationModel(delay: .milliseconds(30))
        let coordinator = PreparationCoordinator(service: PreparationService(model: model))
        coordinator.topic = "Synthetic discussion"
        let work = Task
        {
            await coordinator.prepare(profile: CoachingProfile())
        }
        while !coordinator.isPreparing
        {
            await Task.yield()
        }
        coordinator.clear()
        await work.value
        #expect(coordinator.result == nil && !coordinator.isPreparing && coordinator.topic.isEmpty)
    }

    @Test func inputEditsInvalidatePreviousGuidance() async
    {
        let coordinator = makeCoordinator()
        coordinator.topic = "Synthetic discussion"
        await coordinator.prepare(profile: CoachingProfile())
        coordinator.topic = "A different synthetic discussion"
        #expect(coordinator.result == nil)
    }

    @Test func canceledCallerDoesNotPublishGuidance() async
    {
        let coordinator =
            PreparationCoordinator(service: PreparationService(model: TestPreparationModel(delay: .seconds(5))))
        coordinator.topic = "Synthetic discussion"
        let work = Task
        {
            await coordinator.prepare(profile: CoachingProfile())
        }
        while !coordinator.isPreparing
        {
            await Task.yield()
        }
        work.cancel()
        await work.value
        #expect(coordinator.result == nil && !coordinator.isPreparing)
    }

    private func makeCoordinator() -> PreparationCoordinator
    {
        PreparationCoordinator(service: PreparationService(model: TestPreparationModel(status: .deviceNotEligible)))
    }
}
