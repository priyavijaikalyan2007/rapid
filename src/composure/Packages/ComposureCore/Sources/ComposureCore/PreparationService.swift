// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a01fcdf6-eebb-4a59-b472-f96b06afb273
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Select private generation or labeled fallback under bounded concurrency and cancellation.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

/// Owns the single request slot, fallback selection, and cooperative deadline.
public actor PreparationService
{
    private let model: any CoachingModel
    private let timeout: Duration
    private var isBusy = false

    public init(model: any CoachingModel, timeout: Duration = PreparationLimits.timeout)
    {
        self.model = model
        self.timeout = timeout > .zero && timeout <= PreparationLimits.timeout ? timeout : PreparationLimits.timeout
    }

    public func readiness() async -> ModelReadiness
    {
        await model.readiness()
    }

    public func prepare(_ input: MeetingPreparationInput, profile: CoachingProfile) async throws -> PreparationResult
    {
        try Task.checkCancellation()
        guard !isBusy
        else
        {
            throw PreparationError.busy
        }
        isBusy = true
        defer { isBusy = false }
        let status = await model.readiness()
        try Task.checkCancellation()
        guard status == .available
        else
        {
            return try fallback(input, profile: profile, reason: .unavailable(status))
        }
        do
        {
            let preparation = try await generate(input, profile: profile)
            try Task.checkCancellation()
            return PreparationResult(preparation: preparation, source: .onDevice)
        }
        catch
        {
            try Task.checkCancellation()
            if error is CancellationError
            {
                throw CancellationError()
            }
            return try fallback(input, profile: profile, reason: Self.reason(for: error))
        }
    }

    private func generate(_ input: MeetingPreparationInput, profile: CoachingProfile) async throws -> MeetingPreparation
    {
        let model = model
        let timeout = timeout
        return try await withThrowingTaskGroup(of: MeetingPreparation.self)
        { group in
            defer { group.cancelAll() }
            group.addTask
            {
                try await model.prepare(input, profile: profile)
            }
            group.addTask
            {
                try await Task.sleep(for: timeout)
                throw PreparationError.timeout
            }
            guard let result = try await group.next()
            else
            {
                throw CancellationError()
            }
            return result
        }
    }

    private func fallback(
        _ input: MeetingPreparationInput,
        profile: CoachingProfile,
        reason: PreparationFallbackReason
    ) throws -> PreparationResult
    {
        try PreparationResult(
            preparation: FallbackPreparation.make(input: input, profile: profile),
            source: .profileGuidance(reason)
        )
    }

    private static func reason(for error: any Error) -> PreparationFallbackReason
    {
        switch error as? PreparationError
        {
        case .timeout: return .timeout
        case .refused: return .refused
        case .contextLimit: return .contextLimit
        case .invalidOutput: return .invalidOutput
        default: return .generationFailed
        }
    }
}
