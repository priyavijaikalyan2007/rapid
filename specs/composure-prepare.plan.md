<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: b6b79076-66e1-49bc-b530-3f42492c5030
Created: 2026
-->

<!-- AGENT: Defines the bounded, transient Prepare feature and its verification gates. -->

# Composure Prepare

The owner authorized Phase 2 on 25 October 2026 after confirming setup and profile behavior.
Keep all preparation input, output, and model sessions in memory. Never add them to preferences or diagnostics.
Use the saved profile, rather than unsaved Settings edits, when preparing a conversation.

## Behavior and limits

Accept a required topic, optional outcome and concern, and a high-stakes choice.
Limit topic input to 2,048 UTF-8 bytes, each optional field to 1,024 bytes, and aggregate input to 4,096 bytes.
Return Objective, Watch For, Questions to Ask, If Challenged, and Keep in Mind.
Allow one to three items in each list, at most 280 bytes per item, and at most 4,096 bytes overall.
Render generated content as plain text without interpreting links or Markdown.

Use one on-device generation at a time. Create a fresh LanguageModelSession for each request without tools or history.
Keep fixed instructions separate from a JSON-encoded user prompt. Include only typed profile choices and bounded fields.
Cap responses at 768 tokens. Reserve context for instructions, schema, prompt, and output before generation.
Use exact token counts where the SDK and runtime support them. Older systems use conservative byte budgeting.
Cancel requests after 20 seconds. Framework cancellation is cooperative. Retain the single-work slot until cleanup completes.
Do not retry model requests automatically. Use clearly labeled deterministic profile guidance after controlled model failures.
Cancellation must not publish a fallback or a late result.

Reject invalid input before starting model work. Validate output independently of guided generation.
Give distinct explanations for unavailable Apple Intelligence, unsupported hardware, pending model assets,
model refusal, invalid output, context limits, and timeout. Never display raw framework exceptions.

Retain input during ordinary tab navigation. Cancel generation when Prepare disappears.
On iPhone and iPad, obscure preparation when inactive and clear input and output before background snapshots.
Do not use scene restoration, text autocorrection, spelling services, or automatic text replacement for sensitive fields.
Provide explicit Clear and Cancel controls. Relaunch must show empty preparation fields.

## Design and contracts

Use Adapter for AppleFoundationCoachingModel because the core must be testable without the Apple framework.
Use a small PreparationService to choose between generation and a deterministic function.
No other pattern required - simple function/class suffices for values, validation, and state.
The adapter isolates changing SDK availability and failure cases. It does not introduce a provider registry or cloud path.
Keep rules in ComposureCore, Apple APIs in a second local ComposureModels target, and rendering in SwiftUI.

Contracts:

- MeetingPreparationInput.init(topic:outcome:concern:highStakes:) throws validates bounded inputs.
- MeetingPreparation.init(objective:watchFor:questionsToAsk:ifChallenged:keepInMind:) throws validates the output.
- CoachingModel.readiness() async returns ModelReadiness.
- CoachingModel.prepare(_:profile:) async throws returns a validated MeetingPreparation.
- PreparationService.prepare(_:profile:) async throws returns PreparationResult with its source and fallback reason.
- PreparationCoordinator.prepare(profile:) async drives transient state. cancel() and clear() invalidate obsolete work.
- AppleFoundationCoachingModel implements CoachingModel with the on-device SystemLanguageModel only.

## Files

Create these files in Packages/ComposureCore/Sources/ComposureCore:
PreparationLimits.swift, PreparationError.swift, ModelReadiness.swift, MeetingPreparationInput.swift,
MeetingPreparation.swift, CoachingModel.swift, FallbackPreparation.swift, PreparationFallbackReason.swift,
PreparationSource.swift, PreparationResult.swift, PreparationService.swift, PreparationCoordinator.swift.
Update DiagnosticEvent.swift with fixed preparation events.

Create PreparationValidationTests.swift, FallbackPreparationTests.swift, PreparationServiceTests.swift,
PreparationCoordinatorTests.swift, and PreparationScenarios.swift in the core test target.
Add TestPreparationModel.swift as the isolated asynchronous model fake.

Create these files in Packages/ComposureCore/Sources/ComposureModels:
AppleFoundationCoachingModel.swift, AppleModelReadiness.swift, GeneratedPreparation.swift,
PreparationPrompt.swift, PreparationTokenBudget.swift.
Add PreparationPromptPayload.swift for typed encoding of the transient user prompt.
Create AppleModelTests.swift in Tests/ComposureModelsTests and update Package.swift for the local target and tests.

Create Apps/Shared/PreparationComposition.swift, PrepareView.swift, PreparationFields.swift,
PreparationResultView.swift, and ModelReadinessView.swift.
Update both native root views, AppSection.swift, and CoachingSettingsView.swift.
Update both app entry points to inject one shared preparation service into the windows.
Create Apps/Shared/UnavailablePreparationModel.swift for Debug-only UI-test routing.
Create Apps/iOS/PreparationPrivacyShield.swift and PreparationPrivacyShieldView.swift for synchronous scene snapshot shielding.
Update project.pbxproj for both app memberships and the local ComposureModels product.
Create Tests/UI/PrepareUITests.swift and add it to the existing mobile UI-test target.

Update src/composure/README.md, root README.md, PROJECT.md, ADDITIONAL.md, CONVERSATION.md,
CHANGELOG.md, specs/composure.status.md, and agentknowledge concepts, entities, decisions, and append-only history.
Update this plan when source-level discoveries require a change.

## Security review

Prompt injection and disclosure apply. Keep untrusted text in one bounded prompt, test direct and indirect attacks,
and treat instructions as public. Prompt separation does not guarantee semantic resistance.
No tools, retrieval, agents, executable output, network providers, training, or feedback collection exist.
These boundaries remove tool agency, vector access, and training-poisoning paths from this slice.
Use Apple-managed model assets only. Validate structured output, bound work, and give concise behavioral advice.
Model output can still be unsuitable. Evaluate at least 20 synthetic scenarios before claiming model quality.
Swift strings and system frameworks cannot guarantee erasure from operating-system memory, swap, or diagnostics.
Do not claim physical zeroization or change host-wide settings.

## Verification and checkpoints

Write failing tests before implementation. Cover input/output bounds, eight profile dimensions, high-stakes restraint,
all readiness states, invalid model output, model failures, timeout, cancellation, and stale-result suppression.
Use isolated synthetic scenarios. Inspect at least 20 fallback results. Run actual model evaluations if locally available.
Test prompt separation with direct, quoted, encoded, and multilingual injection fixtures.
Build active and generic Apple silicon Mac targets and both mobile variants.
Run native Prepare journeys on iPhone and iPad simulators, including Clear and empty state after relaunch.
Check privacy shielding and background clearing. Record physical-device and VoiceOver checks separately.
Run source checks and the complete repository suite. Commit and push verified core and integration checkpoints.
