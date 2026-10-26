// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a8aa02b2-f895-41cb-984b-830189570f73
// Created: 2026
// COMPONENT: Reviewed preparation vocabulary
// PURPOSE: Restrict model output to reviewed communication guidance.
// RELATES: GeneratedPreparation
// FLOW: Schema-constrained model choice -> fixed phrase -> validated preparation.

import FoundationModels

/// The model selects context-relevant choices. It cannot introduce arbitrary text into this section.
@Generable
enum PreparationQuestion: String, CaseIterable, Sendable
{
    case perspective
    case concern
    case priority
    case clarify
    case feedback
    case evidence
    case impact
    case scope
    case uncertainty
    case boundary
    case agreement
    case timing

    var phrase: String
    {
        switch self
        {
        case .perspective: return "How do you see this situation?"
        case .concern: return "What is the main concern behind that?"
        case .priority: return "Which outcome matters most to you?"
        case .clarify: return "Could you clarify what you mean?"
        case .feedback: return "What would you like me to understand about this?"
        case .evidence: return "What information led you to that view?"
        case .impact: return "Which part creates the most difficulty for you?"
        case .scope: return "What should this conversation focus on?"
        case .uncertainty: return "What do we know, and what remains uncertain?"
        case .boundary: return "What concern does this limit create for you?"
        case .agreement: return "Where do our views agree, and where do they differ?"
        case .timing: return "What makes that timing important?"
        }
    }
}
