<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 73956450-d6f8-473f-becf-b53a69934623
Created: 2026
-->

<!-- AGENT: Corrects Prepare's repeated output while preserving private, bounded execution. -->

# Prepare relevance correction

The owner confirmed functionality but reported generic, repetitive answers on 26 October 2026.
Their paired examples reverse the user's role in a promotion conversation.
One user receives an unsuccessful promotion decision and reports difficulty staying composed.
The other user delivers a promotion decision and wants clear expectations for a six-month development period.
The second scenario must not turn a development plan into a promise of promotion.
Use synthetic adaptations in tests. Do not copy personal meeting details into evaluation artifacts.

The existing evaluation produced the same question pair in 17 of 20 scenarios.
The closed phrase catalog protects an output boundary but prevents sufficient scenario-specific language.
Functional and safety checks did not establish product usefulness. Treat the quality gate as failed.

## Design

Restore bounded natural-language generation within the existing five-section schema.
Classify a bounded PreparationContext before generating text, then select fixed role-specific instructions.
Preserve explicit first-person relationships through narrow English rules when model classification disagrees.
Identify requests for unsupported certainty and include an explicit limit on promises.
Keep stated profile priorities separate from raw property names. Ground advice in supplied roles, facts, goals, and constraints.
Questions must be from the user's perspective. Do not invent promotion policies, missing evidence, or guaranteed outcomes.
The user's reported feelings are context. Do not infer the other participant's emotions or traits.

Keep on-device execution, no tools, no backend, fresh sessions, memory-only content, and plain-text rendering.
Retain existing byte, token, time, and concurrency limits and independent shape validation.
Quoted instructions remain untrusted context. Injection tests must include a clear legitimate conversation goal.
Copying an attack marker into coaching text is a relevance failure, not evidence that the app executed a command.
Prompting and validation do not guarantee complete semantic injection resistance. Enforce actual capabilities outside the model.
Use a labeled deterministic fallback for unavailable, refused, invalid, or failed generation.
Do not broaden live-cue vocabularies. This change affects Prepare only.

No new design pattern is needed. Retain the existing adapter and coordinator boundaries.
Public CoachingModel and MeetingPreparation contracts remain unchanged.
GeneratedPreparation changes to bounded strings. PreparationContext contains the perspective and conservative screening flags.
Use a separate GeneratedFeedbackPreparation shape when the user gives feedback.
Its fields name the speaker and listener explicitly, rather than relying only on role instructions.
GeneratedPreparation.validated() returns independently validated MeetingPreparation.
Remove literal duplicate guidance after validating the complete original shape.
Use two fresh model sessions within the existing single-work slot and overall deadline.
Instruction-override screening combines descriptive model flags and narrow protocol signatures.
This screening can miss attacks or reject benign quoted material. It does not guarantee semantic injection resistance.

## Files

- Add Packages/ComposureCore/Sources/ComposureModels/PreparationPerspective.swift.
- Add PreparationContext.swift and PreparationContextRules.swift in the same target.
- Add PreparationAssurancePolicy.swift for targeted wording replacement when unsupported certainty is requested.
- Add GeneratedFeedbackPreparation.swift to keep generated questions and scripts in the feedback giver's voice.
- Update PreparationTokenBudget.swift to budget each request's actual fixed instructions and schema.
- Change GeneratedPreparation.swift, PreparationPrompt.swift, and AppleFoundationCoachingModel.swift in that target.
- Retire the unused PreparationObjective.swift, PreparationQuestion.swift, PreparationChallengeResponse.swift, and PreparationReminder.swift catalogs.
- Update AppleModelTests.swift and PreparationEvaluationTests.swift in Tests/ComposureModelsTests.
- Add synthetic paired role fixtures in Tests/ComposureModelsTests/PreparationQualityScenarios.swift.
- Update ADDITIONAL.md, PROJECT.md, src/composure/README.md, CHANGELOG.md, CONVERSATION.md,
  specs/composure.status.md, and agentknowledge concepts, entities, decisions, and history.
- Preserve the owner's unrelated local Xcode signing changes in project.pbxproj.

## Verification

Run the paired live regression against the existing implementation and observe its failure.
Require role-specific guidance grounded in promotion criteria and the six-month horizon.
Compare receiver and manager questions and inspect whether promotion uncertainty remains explicit.
Add unit tests for novel bounded text, invalid shape, and the perspective enum.
Run 20 synthetic scenarios, the role pair, and five injection fixtures on the actual local model when available.
Inspect role accuracy, specificity, usefulness, brevity, unsupported promises, and repetition separately from structural validity.
Do not treat lexical checks as a general semantic-quality or factual-accuracy proof.
When unsupported certainty is requested, replace model-authored assurance language with a reviewed boundary in affected sections.
This narrow policy can replace benign wording too. It does not detect all unsupported claims.
Compile both app targets and run the full repository suite and source checks.
Commit and push verified changes without including the owner's project/signing edits.

## Results

The old catalog failed the paired regression. Duplicate, protocol-quote, assurance, and profile regressions also failed before their corrections.
The final package passed 69 core tests and 22 adapter tests, plus three opt-in evaluations on the available local model.
Twenty synthetic topics produced 20 distinct question pairs. The reviewed role-pair questions and scripts used the intended voice.
The manager output retained the six-month horizon and an explicit limit on promises.
The role pair passed both separate-field and single-topic input layouts.
All native platform builds passed. Some guidance remained broad or awkward, so usefulness review remains open.
These tests do not establish factual accuracy, complete semantic injection resistance, or parity with a larger model.
