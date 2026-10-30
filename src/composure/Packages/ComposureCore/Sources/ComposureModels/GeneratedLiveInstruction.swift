// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000123
// Created: 2026
// COMPONENT: Live semantic situation classification
// PURPOSE: Separate situation recognition from sparse personalized instruction generation.
// RELATES: AppleFoundationCoachingModel, LiveCoachingPrompt
// FLOW: Bounded speech -> situation or silence -> contextual instruction -> independent validation.

import FoundationModels

/// The action comes from the classified situation. Only its short contextual wording is generated here.
@Generable
struct GeneratedLiveInstruction
{
    @Guide(
        description: "One concrete English imperative, 5 to 12 words, at most 18. No quotes or participant assessment."
    )
    var instruction: String
}
