// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: da311424-e925-44cd-9687-3bd22c711d7e
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Keep fallback reasons visible and distinct without sensitive diagnostic payloads.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

/// Describes why fixed profile guidance was selected, without retaining an exception.
public enum PreparationFallbackReason: Sendable, Equatable
{
    case unavailable(ModelReadiness)
    case generationFailed
    case refused
    case invalidOutput
    case contextLimit
    case timeout

    public var explanation: String
    {
        switch self
        {
        case .unavailable(let readiness): return readiness.explanation
        case .generationFailed: return PreparationError.generationFailed.errorDescription ?? "Profile guidance is available."
        case .refused: return PreparationError.refused.errorDescription ?? "Profile guidance is available."
        case .invalidOutput: return PreparationError.invalidOutput.errorDescription ?? "Profile guidance is available."
        case .contextLimit: return PreparationError.contextLimit.errorDescription ?? "Profile guidance is available."
        case .timeout: return PreparationError.timeout.errorDescription ?? "Profile guidance is available."
        }
    }
}
