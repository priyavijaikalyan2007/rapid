// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000102
// Created: 2026
// COMPONENT: Native Mac live coaching
// PURPOSE: Present explicit listening controls and one brief cue without transcript display or persistence.
// RELATES: MacLiveCoachComposition, LiveSessionCoordinator, MacCuePanel
// FLOW: Explicit Start -> selected audio -> private coaching -> floating cue -> Stop and clear.

#if DEBUG
import ComposureCore

/// UI tests never invoke native model generation.
actor UITestLiveModel: LiveCoachingModel
{
    func readiness() -> ModelReadiness
    {
        .available
    }

    func evaluate(_ input: LiveCoachingInput) throws -> CueProposal?
    {
        guard let evidence = input.events.last
        else
        {
            return nil
        }
        return try CueProposal(
            kind: .askFirst,
            instruction: "Ask which promotion criteria remain unmet.",
            confidence: 0.9,
            evidenceID: evidence.id
        )
    }
}
#endif
