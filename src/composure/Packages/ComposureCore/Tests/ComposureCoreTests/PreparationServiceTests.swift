// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 08a0c05c-e163-4096-9739-51198689c5c1
// Created: 2026
// COMPONENT: Preparation regression tests
// PURPOSE: Verify bounded, transient coaching without real conversation content.
// RELATES: PreparationService, MeetingPreparation
// FLOW: Synthetic input -> preparation contract -> bounded result or controlled failure.

import Testing
@testable import ComposureCore

struct PreparationServiceTests
{
    @Test(arguments: ModelReadiness.allCases.filter
    {
        $0 != .available
    })
    func unavailableModelUsesProfileGuidance(readiness: ModelReadiness) async throws
    {
        let model = TestPreparationModel(status: readiness)
        let result = try await PreparationService(model: model).prepare(input(), profile: CoachingProfile())
        #expect(result.source == .profileGuidance(.unavailable(readiness)))
        #expect(await model.calls == 0)
    }

    @Test func availableModelReturnsValidatedResult() async throws
    {
        let result = try await PreparationService(model: TestPreparationModel()).prepare(
            input(),
            profile: CoachingProfile()
        )
        #expect(result.source == .onDevice)
    }

    @Test func failureUsesLabeledFallback() async throws
    {
        let model = TestPreparationModel(failure: .generationFailed)
        let result = try await PreparationService(model: model).prepare(input(), profile: CoachingProfile())
        #expect(result.source == .profileGuidance(.generationFailed))
    }

    @Test func timeoutUsesLabeledFallback() async throws
    {
        let model = TestPreparationModel(delay: .seconds(5))
        let result = try await PreparationService(model: model, timeout: .milliseconds(5))
            .prepare(input(), profile: CoachingProfile())
        #expect(result.source == .profileGuidance(.timeout))
    }

    @Test func cancellationDoesNotProduceAdvice() async throws
    {
        let service = PreparationService(model: TestPreparationModel(delay: .seconds(5)))
        let input = try input()
        let work = Task
        {
            try await service.prepare(input, profile: CoachingProfile())
        }
        work.cancel()
        await #expect(throws: CancellationError.self) { try await work.value }
    }

    @Test func overlappingModelWorkIsRejected() async throws
    {
        let model = TestPreparationModel(delay: .seconds(5))
        let service = PreparationService(model: model)
        let input = try input()
        let first = Task
        {
            try await service.prepare(input, profile: CoachingProfile())
        }
        while await model.calls == 0
        {
            await Task.yield()
        }
        await #expect(throws: PreparationError.busy) { try await service.prepare(input, profile: CoachingProfile()) }
        first.cancel()
        _ = try? await first.value
    }

    @Test(arguments: [PreparationError.refused, .invalidOutput, .contextLimit])
    func controlledFailuresRemainDistinct(failure: PreparationError) async throws
    {
        let result = try await PreparationService(model: TestPreparationModel(failure: failure))
            .prepare(input(), profile: CoachingProfile())
        let expected: PreparationFallbackReason = switch failure
        {
        case .refused: .refused
        case .invalidOutput: .invalidOutput
        default: .contextLimit
        }
        #expect(result.source == .profileGuidance(expected))
    }

    private func input() throws -> MeetingPreparationInput
    {
        try MeetingPreparationInput(topic: "Synthetic planning discussion")
    }
}
