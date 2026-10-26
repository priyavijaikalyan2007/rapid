// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 5411227a-4947-45df-bde2-8064021b3bcc
// Created: 2026
// COMPONENT: Reviewed preparation vocabulary
// PURPOSE: Restrict model output to reviewed communication guidance.
// RELATES: GeneratedPreparation
// FLOW: Schema-constrained model choice -> fixed phrase -> validated preparation.

import FoundationModels

/// The model selects context-relevant choices. It cannot introduce arbitrary text into this section.
@Generable
enum PreparationChallengeResponse: String, CaseIterable, Sendable
{
    case clarifyConcern
    case acknowledge
    case stateUncertainty
    case pause
    case holdBoundary

    var phrase: String
    {
        switch self
        {
        case .clarifyConcern: return "What is the main concern behind that question?"
        case .acknowledge: return "I hear the concern. May I explain how I see it?"
        case .stateUncertainty: return "I do not know that yet. Which part should we clarify first?"
        case .pause: return "Let me pause and make sure I understand your point."
        case .holdBoundary: return "I understand the concern. This is the limit I can commit to."
        }
    }
}
