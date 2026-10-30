// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000066
// Created: 2026
// COMPONENT: Native live coaching adapter
// PURPOSE: Translate native speech and model results into bounded validated transient contracts.
// RELATES: MacMeetingAudioSource, LiveSessionCoordinator, AppleFoundationCoachingModel
// FLOW: Explicit listening -> native on-device processing -> validated event or brief cue.

import ComposureCore
import FoundationModels

extension AppleFoundationCoachingModel: LiveCoachingModel
{
    /// Shares Prepare's one work slot. Each opportunity uses a fresh tool-free session.
    public func evaluate(_ input: LiveCoachingInput) async throws -> CueProposal?
    {
        try Task.checkCancellation()
        guard !isBusy, readiness() == .available, !input.events.isEmpty
        else
        {
            throw LiveSessionError.modelUnavailable
        }
        isBusy = true
        defer { isBusy = false }
        let generated = try await generateLiveCue(input)
        return try generated.validated(for: input)
    }

    /// Classify before personalization so profile priorities cannot create a cue without a useful situation.
    private func generateLiveCue(_ input: LiveCoachingInput) async throws -> GeneratedLiveCue
    {
        let prompt = try LiveCoachingPrompt.make(input)
        let fields = input.events.map(\.text).joined(separator: " ") + " " + input.objective
        if PreparationContextRules.hasProtocolOverride(fields)
        {
            return Self.silence
        }
        let context = try await liveResponse(
            GeneratedLiveSituation.self,
            prompt: prompt,
            instructions: LiveCoachingPrompt.classificationInstructions,
            maximumTokens: 96
        )
        guard context.situation.action != .noAction, context.confidence >= 0.8,
              input.events.indices.contains(context.evidenceIndex)
        else
        {
            return Self.silence
        }
        let instructions = LiveCoachingPrompt.instructions + "\n" + context.situation.guidance
        let wording = try await liveResponse(
            GeneratedLiveInstruction.self,
            prompt: prompt,
            instructions: instructions,
            maximumTokens: 96
        )
        return GeneratedLiveCue(
            action: context.situation.action,
            confidence: context.confidence,
            evidenceIndex: context.evidenceIndex,
            instruction: wording.instruction
        )
    }

    private static var silence: GeneratedLiveCue
    {
        GeneratedLiveCue(action: .noAction, confidence: 1, evidenceIndex: 0, instruction: "")
    }

    private func liveResponse<Content: Generable>(
        _ type: Content.Type, prompt: String, instructions: String, maximumTokens: Int
    ) async throws -> Content
    {
        try await PreparationTokenBudget.validate(
            prompt: prompt,
            model: .default,
            instructions: instructions,
            schema: Content.generationSchema
        )
        try Task.checkCancellation()
        let session = LanguageModelSession(model: .default, instructions: instructions)
        do
        {
            let response = try await session.respond(
                to: prompt,
                generating: type,
                options: GenerationOptions(
                    temperature: 0,
                    maximumResponseTokens: maximumTokens
                )
            )
            try Task.checkCancellation()
            return response.content
        }
        catch
        {
            try Task.checkCancellation()
            throw LiveSessionError.modelUnavailable
        }
    }
}
