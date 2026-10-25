// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: bc0e062d-3ccc-4d7a-ae7e-c9dd49a3232e
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Reject excessive or invalid text before constructing a preparation request.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

import Foundation

/// A transient value. Deliberately does not conform to Codable or any persistence contract.
public struct MeetingPreparationInput: Sendable, Equatable
{
    public let topic: String
    public let outcome: String
    public let concern: String
    public let highStakes: Bool

    public init(topic: String, outcome: String = "", concern: String = "", highStakes: Bool = false) throws
    {
        guard !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else
        {
            throw PreparationError.topicRequired
        }
        let fields = [topic, outcome, concern]
        guard topic.utf8.count <= PreparationLimits.topicBytes,
              outcome.utf8.count <= PreparationLimits.optionalFieldBytes,
              concern.utf8.count <= PreparationLimits.optionalFieldBytes,
              fields.reduce(0, {
                  $0 + $1.utf8.count
              }) <= PreparationLimits.totalInputBytes
        else
        {
            throw PreparationError.inputTooLong
        }
        guard !fields.contains(where: PreparationLimits.containsDisallowedControls)
        else
        {
            throw PreparationError.invalidInput
        }
        self.topic = topic
        self.outcome = outcome
        self.concern = concern
        self.highStakes = highStakes
    }
}
