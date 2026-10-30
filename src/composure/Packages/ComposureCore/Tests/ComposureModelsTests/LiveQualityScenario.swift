// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000001
// Created: 2026
// COMPONENT: Cross-topic live coaching evaluation
// PURPOSE: Separate invented development examples from untouched verification cases.
// RELATES: LiveQualityEvaluationTests, AppleFoundationCoachingModel
// FLOW: Frozen synthetic conversation -> on-device decision -> acceptable action or deliberate silence.

import ComposureCore

/// Invented evaluation material. Expected actions are sets, not exact generated wording.
struct LiveQualityScenario
{
    let id: String
    let objective: String
    let context: [String]
    let current: String
    let expected: Set<String>
    let focus: CoachingFocus?

    init(
        id: String, objective: String, context: [String] = [], current: String,
        expected: Set<String> = [], focus: CoachingFocus? = nil
    )
    {
        self.id = id
        self.objective = objective
        self.context = context
        self.current = current
        self.expected = expected
        self.focus = focus
    }
}
