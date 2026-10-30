// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000063
// Created: 2026
// COMPONENT: Native live coaching adapter
// PURPOSE: Translate native speech and model results into bounded validated transient contracts.
// RELATES: MacMeetingAudioSource, LiveSessionCoordinator, AppleFoundationCoachingModel
// FLOW: Explicit listening -> native on-device processing -> validated event or brief cue.

import FoundationModels

/// The model can choose silence or a supported action. It cannot create a new behavioral category.
@Generable
enum LiveCueAction: String
{
    case noAction
    case askFirst
    case answerDirectly
    case clarify
    case dontGuess
    case decisionFocus
}
