// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000122
// Created: 2026
// COMPONENT: Live semantic situation classification
// PURPOSE: Separate situation recognition from sparse personalized instruction generation.
// RELATES: AppleFoundationCoachingModel, LiveCoachingPrompt
// FLOW: Bounded speech -> situation or silence -> contextual instruction -> independent validation.

import FoundationModels

/// Classification comes before personalization so a profile cannot turn every remark into the same cue.
@Generable
struct GeneratedLiveSituation
{
    @Guide(description: "Current situation in the speech. Usually noAction.")
    var situation: LiveSituation
    @Guide(description: "Zero-based index from the excerpt index field", .range(0 ... 7))
    var evidenceIndex: Int
    @Guide(description: "Confidence that an intervention is useful now", .range(0 ... 1))
    var confidence: Double
}
