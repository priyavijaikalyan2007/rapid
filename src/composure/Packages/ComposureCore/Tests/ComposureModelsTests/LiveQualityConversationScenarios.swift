// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 441ff05f-ec98-45cf-a7a5-3952d76f854d
// Created: 2026
// COMPONENT: Shared invented conversation fixtures
// PURPOSE: Keep the same timed invented turns in the production-adapter regression and local-model comparison.
// RELATES: AppleFoundationCoachingModel, LiveCoachingInput, CueArbiter
// FLOW: Timestamped synthetic turns -> current bounded context -> model -> actual arbitration and silence.

/// The conversation expectations predate replacement-model evaluation.
enum LiveQualityConversationScenarios
{
    struct Turn
    {
        let offset: Double
        let text: String
        let expected: Set<String>
    }

    static let cases: [Turn] = [
        Turn(
            offset: 0,
            text: "You were not promoted. You need to show more leadership.",
            expected: ["clarify", "askFirst"]
        ),
        Turn(
            offset: 6,
            text: "This is ridiculous. I am going to send an insulting reply now and walk out.",
            expected: ["pause"]
        ),
        Turn(
            offset: 30,
            text: "I have no evidence, but I know the committee secretly intends to block every future opportunity for me.",
            expected: ["dontGuess", "rephrase"]
        ),
        Turn(
            offset: 60,
            text: """
                We listed several development actions, but no one owns writing the criteria and we still have no date \
                for a review.
                """,
            expected: ["decisionFocus"]
        ),
        Turn(
            offset: 90,
            text: """
                Agreed. I will bring the design-review examples, my manager will write the criteria by Friday, and we \
                will meet on Tuesday.
                """,
            expected: []
        )
    ]
}
