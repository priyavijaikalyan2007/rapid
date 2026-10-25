// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c7fcae24-e016-416b-9c26-2207886d622d
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Describe failures with fixed recovery messages without exposing sensitive text.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

import Foundation

/// Fixed errors never include user text, model content, or raw framework diagnostics.
public enum PreparationError: Error, LocalizedError, Sendable, Equatable
{
    case topicRequired
    case inputTooLong
    case invalidInput
    case invalidOutput
    case contextLimit
    case generationFailed
    case refused
    case timeout
    case busy

    public var errorDescription: String?
    {
        switch self
        {
        case .topicRequired: return "Enter a conversation topic before preparing."
        case .inputTooLong: return "Shorten the topic or optional fields to fit the displayed limits."
        case .invalidInput: return "Remove unsupported control characters and try again."
        case .invalidOutput: return "The model's response did not meet preparation limits. Profile guidance is available."
        case .contextLimit: return "This request exceeds the model's context budget. Profile guidance is available."
        case .generationFailed: return "The on-device model could not finish. Profile guidance is available."
        case .refused: return "The on-device model declined this request. Profile guidance is available."
        case .timeout: return "The on-device model reached the time limit. Profile guidance is available."
        case .busy: return "The previous request is stopping. Wait a moment before trying again."
        }
    }
}
