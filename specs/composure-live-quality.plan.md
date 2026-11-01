<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 79ac0567-8144-4e51-84e6-ff5b334e28ac
Created: 2026
-->

<!-- AGENT: Diagnose quiet live coaching and evaluate useful interventions across conversation topics. -->

# Live coaching usefulness correction

The owner reported only one CLARIFY cue during the suggested two-person promotion exercise.
They used speakers in a quiet room and expected help after harsh comments. They also questioned whether
promotion-only tuning would bias the app. Treat this as a failed usefulness checkpoint, not proof that
the current frequency is appropriate. Do not infer the owner's emotional state or claim a measured cause.

## Findings to test

The old evaluation covers two isolated promotion utterances, four routine remarks, and three override fixtures.
It does not test a progressing conversation. The model can select older context as evidence while the
arbiter rejects evidence older than 12 seconds. Two question situations map to CLARIFY, whose entire kind
is then suppressed for 90 seconds. Harsh wording has no explicit rephrase action. No content-free decision
breakdown distinguishes intentional silence, ignored speech results, failed model work, or suppression.

## Design

Keep the existing Apple Adapter and testable model/source contracts. No new GoF pattern is required for
bounded values, pure duplicate checks, or metrics. Keep audio capture, OS permissions, storage, and speaker
attribution unchanged. UI code renders state and issues actions. Core services retain processing rules.

Freeze development and separate verification fixtures before prompt changes. Cover promotion, disagreement,
feedback, negotiation, planning, technical review, ordinary agreement, personal criticism, and non-work discussion.
All fixtures are invented. They are evaluation inputs, not training data. Do not tune against the verification
results. Any later use of a failed verification case for tuning requires a fresh verification set.

Core files under `Packages/ComposureCore/Sources/ComposureCore`:

- `LiveCoachingInput.swift`: expose the latest meaningful finalized event as the current evidence anchor.
  Accept a bounded recent-cue context through an optional defaulted parameter.
- `RecentCueContext.swift`: validated recent action and wording for one fresh request, at most four cues.
- `CueKind.swift`, `CuePriority.swift`, and `CueProposal.swift`: add forward-looking PAUSE and REPHRASE actions.
  PAUSE and REPHRASE receive fixed high priority. The model does not choose arbitrary urgency.
- `CueDecision.swift`, `CueSuppressionReason.swift`, `CueRepeatKey.swift`, and `CueArbiter.swift`:
  return a cue or fixed rejection reason. Keep `consider` as a compatibility wrapper. Suppress repeated
  advice instead of every action with the same headline. Retain 90-second repeat suppression, normal
  cooldowns, and profile caps. A high-priority pause can replace a normal cue, with its own bounded cooldown.
- `LiveSessionDiagnostics.swift` and `LiveCoachingOutcome.swift`: bounded numeric counters and closed outcomes.
- `ConversationBuffer.swift`: report whether an insertion was accepted without changing revision semantics.
- `LiveSessionCoordinator.swift`: count input, decisions, failures, and suppressions. Carry bounded recent cues
  into generation. Clear diagnostics and recent context on Stop. Preserve cancellation and stale-session checks.

Native model files under `Sources/ComposureModels`:

- `LiveCoachingPrompt.swift`: separate current speech from earlier context, include recent advice, remove
  promotion-specific examples, and describe observable criticism or rash replies without emotional diagnosis.
- `GeneratedLiveSituation.swift`: classify current speech without letting a model select older evidence.
- `LiveSituation.swift`, `LiveCueAction.swift`, and `AppleFoundationCoachingModel+Live.swift`: select supported
  behavioral actions, bind evidence to the current event, and keep all existing byte/token/time/tool limits.
- `GeneratedLiveCue.swift`: independently validate the final instruction and current evidence.

UI file `Apps/macOS/MacLiveCoachView.swift` gains a Debug-only diagnostics section. It contains numeric
counts and fixed status text only. It has no audio, transcript, prompt, or generated-instruction history.
Counts reset on Stop. Add no model API, preference key, or native resource management to the view.

Tests under the matching core/model test directories:

- Extend `CueArbiterTests.swift`, `LiveSessionCoordinatorTests.swift`, `ConversationBufferTests.swift`, and
  `LiveCoachingModelTests.swift` for current evidence, new advice, priority, counters, cleanup, and bounded context.
- Add `LiveQualityScenario.swift`, `LiveQualityDevelopmentScenarios.swift`, and
  `LiveQualityVerificationScenarios.swift` as frozen invented fixtures.
- Add `LiveQualityEvaluationTests.swift` for independent fixture evaluation. Add `LiveConversationQualityTests.swift`
  for a progressing conversation through the real model and arbiter. Use separate opt-in flags.
- Extend `Tests/MacUI/LiveCoachUITests.swift` to verify content-free diagnostics and clearing without capture.

Update `README.md`, `CHANGELOG.md`, `CONVERSATION.md`, `PROJECT.md`, `ADDITIONAL.md`,
`specs/composure.status.md`, and relevant graph concepts/entities/decisions/history when behavior changes.
The Xcode project already discovers package tests and the existing view. Preserve its owner changes.

## Verification and limits

Run failing tests before behavior changes. Run baseline real-model development fixtures before tuning.
Keep assertions about useful action kinds, current evidence, deliberate silence, and topic fit rather than
requiring exact generated phrases. Record missed cases and false interventions. Cue count alone is not quality.
Freeze a candidate before running the separate verification set. Report the small sample's limits honestly.

Run core/native regressions, all-platform builds after core changes, Mac Release compilation, native UI
journeys, style checks, and the full repository command. Commit and push verified checkpoints as work proceeds.
Do not ask the owner to repeat the same trial before these checks show a concrete improvement.
Speaker-specific timing and interruption detection remain disabled on unverified speaker routes.


## Frozen fixture sets

Before prompt changes, freeze 12 development cases and eight separate verification cases.
Development SHA-256: `f639e08df4055b26c2a50c1518db1ce94033c94cad246da468133c74bedbceb4`.
Verification SHA-256: `40e1074290a0ac305a55963e468ea7fd3b83ed0e54ef6623160f1ea8adb5793a`.
The verification set has no promotion scenario. It includes customer, architecture, compensation,
household, volunteer, classroom, support, and technical-review conversations.
This small authored set is a separate regression check, not a statistically representative or independent human benchmark.


## Development baseline and core checkpoint

Frozen fixture checkpoint 5b932c3 reached origin/main before prompt changes.
The original model passed nine of 12 development action-selection checks. It missed personal criticism,
a rash reply, and a vague design request. The project-criticism case produced a promotion-specific sentence.
The negotiation case passed its action-kind check but produced only "DontGuess", which is not useful wording.
The action-kind score therefore overstates baseline quality. No verification case was run.

New core regressions failed before the required contracts existed, then passed with current-event anchoring,
bounded recent-advice context, reasoned suppression, and transient numeric counters. Distinct advice can
reuse a headline after the normal cooldown. Lexically similar repeated advice stays suppressed for 90 seconds.
PAUSE and REPHRASE share fixed high priority, an eight-second high-priority cooldown, and all profile caps.
The entire pause/rephrase action remains repeat-suppressed to prevent urgent paraphrase spam.
Core regression checks passed 127 core tests and 60 native test declarations with opt-ins skipped.
The model/prompt correction and Debug diagnostics view remain in progress at this checkpoint.

## Model experiments rejected on 1 November 2026

The Debug diagnostics section passed three synthetic Mac UI journeys. A focused rerun captured the main
window for visual review. The section shows numeric counts and a fixed outcome, then disappears on Stop.
Short meaningful input tests first failed for "Ridiculous!", "You idiot.", and "Why?". They now pass while
filler-only speech remains excluded. All-platform compilation and 129 core regressions passed.

The original model showed only CLARIFY in the five-turn synthetic conversation. It reused old wording,
failed current evidence checks on later opportunities, and missed the later decision cue.
Tested prompt revisions included current-versus-previous fields, recent-advice context, explicit pause and
rephrase categories, narrower situation sets, and literal-speech observation schemas. Some revisions passed
all 12 development action checks but still failed unchanged multi-turn expectations. Other revisions reduced
recall or produced false interventions during routine agreement. Development scores alone did not justify adoption.

Rejected all native model/prompt experiments and restored the committed model adapter. No model weights
changed. Keep the failing opt-in conversation benchmark as visible evidence of the unmet quality gate.
The separate eight-case verification set remains unused because no candidate met the development gate.
Its two frozen fixture hashes remain unchanged. Do not tune against this future verification set.

The model pipeline remains unsuitable for a usefulness acceptance claim. This result describes the tested
pipeline and examples. It does not prove that every Apple model implementation must fail.
The next design decision is whether to evaluate a stronger downloaded on-device model or narrow V1 coaching.
Both directions preserve the prohibition on uploads. A larger model adds storage, memory, licensing, and
device-support work. No new model dependency or download was added during this investigation.
Do not request another promotion trial until a candidate passes the broader and multi-turn gates.
