// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 5d5de3cc-06bb-4c54-85a1-40cd7e41f55a
// Created: 2026
// COMPONENT: On-device preparation adapter
// PURPOSE: Use only the on-device model with a fresh session and controlled errors for every request.
// RELATES: CoachingModel, PreparationService
// FLOW: Bounded user prompt -> fresh on-device session -> independently validated preparation.

import ComposureCore
import Foundation
import FoundationModels

/// Owns no persistent transcript. The framework session is local to each bounded request.
public actor AppleFoundationCoachingModel: CoachingModel
{
    private var isBusy = false
    public init()
    {
    }

    public func readiness() -> ModelReadiness
    {
        let model = SystemLanguageModel.default
        let status = AppleModelReadiness.map(model.availability)
        guard status == .available
        else
        {
            return status
        }
        return model.supportsLocale(Locale(identifier: "en")) ? .available : .otherUnavailable
    }

    public func prepare(_ input: MeetingPreparationInput, profile: CoachingProfile) async throws -> MeetingPreparation
    {
        try Task.checkCancellation()
        guard !isBusy
        else
        {
            throw PreparationError.busy
        }
        guard readiness() == .available
        else
        {
            throw PreparationError.generationFailed
        }
        isBusy = true
        defer { isBusy = false }
        do
        {
            return try await generate(input, profile: profile)
        }
        catch
        {
            try Task.checkCancellation()
            throw Self.controlledError(error)
        }
    }

    private func generate(_ input: MeetingPreparationInput, profile: CoachingProfile) async throws -> MeetingPreparation
    {
        let model = SystemLanguageModel.default
        let prompt = try PreparationPrompt.make(input: input, profile: profile)
        try await PreparationTokenBudget.validate(prompt: prompt, model: model)
        try Task.checkCancellation()
        let session = LanguageModelSession(model: model, instructions: PreparationPrompt.instructions)
        let options = GenerationOptions(temperature: 0, maximumResponseTokens: PreparationLimits.outputTokens)
        let response = try await session.respond(to: prompt, generating: GeneratedPreparation.self, options: options)
        try Task.checkCancellation()
        return try response.content.validated()
    }

    /// Error descriptions can contain prompts. Only enum categories cross the adapter boundary.
    private static func controlledError(_ error: any Error) -> PreparationError
    {
        if let controlled = error as? PreparationError
        {
            return controlled
        }
        #if compiler(>=6.4)
        if #available(macOS 27, iOS 27, *), let failure = error as? LanguageModelError
        {
            switch failure
            {
            case .contextSizeExceeded: return .contextLimit
            case .refusal, .guardrailViolation: return .refused
            default: return .generationFailed
            }
        }
        #endif
        if let failure = error as? LanguageModelSession.GenerationError
        {
            switch failure
            {
            case .exceededContextWindowSize: return .contextLimit
            case .refusal, .guardrailViolation: return .refused
            case .decodingFailure: return .invalidOutput
            default: return .generationFailed
            }
        }
        return .generationFailed
    }
}
