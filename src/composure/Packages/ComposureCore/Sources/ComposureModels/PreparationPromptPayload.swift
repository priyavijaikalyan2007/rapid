// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 26034310-afa0-4017-8dec-3f8d8f2b76fa
// Created: 2026
// COMPONENT: On-device preparation adapter
// PURPOSE: Encode bounded user context separately from privileged model instructions.
// RELATES: CoachingModel, PreparationService
// FLOW: Bounded user prompt -> fresh on-device session -> independently validated preparation.

import ComposureCore

/// Encoded only for the transient user prompt. No storage interface accepts this type.
struct PreparationPromptPayload: Encodable
{
    let topic: String
    let outcome: String
    let concern: String
    let highStakes: Bool
    let focusPriorities: [String]
    let executiveRestraint: Bool
}
