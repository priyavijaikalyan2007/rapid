// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 8e4d5cb1-d82f-4192-bf49-aef964f3d067
// Created: 2026
// COMPONENT: On-device preparation adapter
// PURPOSE: Bound the complete model context with exact counters or conservative legacy budgeting.
// RELATES: CoachingModel, PreparationService
// FLOW: Bounded user prompt -> fresh on-device session -> independently validated preparation.

import ComposureCore
import Foundation
import FoundationModels

/// Include instructions and schema in the context budget, not just the user's text.
enum PreparationTokenBudget
{
    static func validate(prompt: String, model: SystemLanguageModel) async throws
    {
        let instructions = PreparationPrompt.instructions
        let schema = GeneratedPreparation.generationSchema
        #if compiler(>=6.3)
        if #available(macOS 26.4, iOS 26.4, *)
        {
            let count = try await model.tokenCount(for: Prompt(prompt)) +
                model.tokenCount(for: Instructions(instructions)) + model.tokenCount(for: schema)
            try validateCount(count, contextSize: min(model.contextSize, PreparationLimits.contextTokens))
            return
        }
        #endif
        // The older tokenizer API has no public counter. Budget every encoded byte as a token,
        // reserve framing space, and fall back rather than shorten instructions or user content.
        let schemaBytes = try JSONEncoder().encode(schema).count
        try validateCount(
            prompt.utf8.count + instructions.utf8.count + schemaBytes,
            contextSize: PreparationLimits.contextTokens
        )
    }

    static func validateCount(_ count: Int, contextSize: Int) throws
    {
        guard count >= 0, count <= PreparationLimits.inputTokens,
              count + PreparationLimits.outputTokens + PreparationLimits.contextReserveTokens <= contextSize
        else
        {
            throw PreparationError.contextLimit
        }
    }
}
