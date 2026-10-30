// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000064
// Created: 2026
// COMPONENT: Native live coaching adapter
// PURPOSE: Translate native speech and model results into bounded validated transient contracts.
// RELATES: MacMeetingAudioSource, LiveSessionCoordinator, AppleFoundationCoachingModel
// FLOW: Explicit listening -> native on-device processing -> validated event or brief cue.

import ComposureCore
import FoundationModels

/// Guided generation is followed by independent validation before an instruction is displayed.
@Generable
struct GeneratedLiveCue
{
    @Guide(description: "Usually noAction. Choose an action only when it materially helps now.")
    var action: LiveCueAction
    @Guide(description: "Confidence that this intervention helps now", .range(0 ... 1))
    var confidence: Double
    @Guide(description: "Index of the recent excerpt that justifies this action", .range(0 ... 7))
    var evidenceIndex: Int
    @Guide(description: "One concrete English instruction, 5 to 12 words, at most 18. Empty for noAction.")
    var instruction: String

    func validated(for input: LiveCoachingInput) throws -> CueProposal?
    {
        guard confidence.isFinite, confidence >= 0, confidence <= 1
        else
        {
            throw LiveSessionError.invalidCue
        }
        guard confidence >= 0.8
        else
        {
            return nil
        }
        guard action != .noAction
        else
        {
            return nil
        }
        guard input.events.indices.contains(evidenceIndex), let kind = CueKind(rawValue: action.rawValue)
        else
        {
            throw LiveSessionError.invalidCue
        }
        return try CueProposal(
            kind: kind,
            instruction: instruction,
            confidence: confidence,
            evidenceID: input.events[evidenceIndex].id
        )
    }
}
