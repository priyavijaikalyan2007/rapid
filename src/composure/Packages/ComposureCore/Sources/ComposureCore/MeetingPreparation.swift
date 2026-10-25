// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 40ae4fab-c50a-4b68-b001-ede164d2d3b7
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Validate all preparation sections before native views can display them.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

import Foundation

/// Independent validation is required even when the provider uses guided generation.
public struct MeetingPreparation: Sendable, Equatable
{
    public let objective: String
    public let watchFor: [String]
    public let questionsToAsk: [String]
    public let ifChallenged: String
    public let keepInMind: [String]

    public init(
        objective: String,
        watchFor: [String],
        questionsToAsk: [String],
        ifChallenged: String,
        keepInMind: [String]
    ) throws
    {
        let lists = [watchFor, questionsToAsk, keepInMind]
        guard lists.allSatisfy({
            (1 ... 3).contains($0.count)
        }) else
        {
            throw PreparationError.invalidOutput
        }
        let fields = [objective, ifChallenged] + lists.flatMap
        {
            $0
        }
        guard fields.allSatisfy(Self.validItem),
              fields.reduce(0, {
                  $0 + $1.utf8.count
              }) <= PreparationLimits.totalOutputBytes
        else
        {
            throw PreparationError.invalidOutput
        }
        self.objective = objective
        self.watchFor = watchFor
        self.questionsToAsk = questionsToAsk
        self.ifChallenged = ifChallenged
        self.keepInMind = keepInMind
    }

    private static func validItem(_ item: String) -> Bool
    {
        !item.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            item.utf8.count <= PreparationLimits.outputItemBytes &&
            !PreparationLimits.containsDisallowedControls(item)
    }
}
