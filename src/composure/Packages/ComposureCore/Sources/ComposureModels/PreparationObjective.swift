// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 6e5b994d-33b1-4a51-bc28-0740536801a4
// Created: 2026
// COMPONENT: Reviewed preparation vocabulary
// PURPOSE: Restrict model output to reviewed communication guidance.
// RELATES: GeneratedPreparation
// FLOW: Schema-constrained model choice -> fixed phrase -> validated preparation.

import FoundationModels

/// The model selects context-relevant choices. It cannot introduce arbitrary text into this section.
@Generable
enum PreparationObjective: String, CaseIterable, Sendable
{
    case clarify
    case understand
    case feedback
    case boundary
    case disagreement
    case uncertainty
    case introduce
    case focus

    var phrase: String
    {
        switch self
        {
        case .clarify: return "Clarify the request and the outcome each person expects."
        case .understand: return "Understand the other person's perspective before explaining your own."
        case .feedback: return "Give one specific observation and invite the other person's response."
        case .boundary: return "State your limit clearly and ask how you can move forward within it."
        case .disagreement: return "Explain the difference in views and seek the concern behind it."
        case .uncertainty: return "Separate what you know from what remains uncertain."
        case .introduce: return "Give the main point briefly and invite questions."
        case .focus: return "Bring the discussion back to its intended outcome."
        }
    }
}
