// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f2b30874-f001-4e8d-af7c-e7076d8e0eea
// Created: 2026
// COMPONENT: Reviewed preparation vocabulary
// PURPOSE: Restrict model output to reviewed communication guidance.
// RELATES: GeneratedPreparation
// FLOW: Schema-constrained model choice -> fixed phrase -> validated preparation.

import FoundationModels

/// The model selects context-relevant choices. It cannot introduce arbitrary text into this section.
@Generable
enum PreparationReminder: String, CaseIterable, Sendable
{
    case pause
    case concise
    case listen
    case curious
    case uncertain
    case outcome
    case respect
    case executive

    var phrase: String
    {
        switch self
        {
        case .pause: return "Pause before answering a difficult question."
        case .concise: return "Give the main point first and add detail when asked."
        case .listen: return "Let the other person finish before you respond."
        case .curious: return "Ask one clarifying question before defending your view."
        case .uncertain: return "State uncertainty clearly."
        case .outcome: return "Return to the intended outcome when the discussion drifts."
        case .respect: return "Acknowledge a concern before explaining your position."
        case .executive: return "Give your shortest useful answer, then wait."
        }
    }
}
