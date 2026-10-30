<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: a2ef741c-3430-4c57-915c-379767f04437
Created: 2026
-->

<!-- AGENT: File-level design and evidence for the first usable Mac live coaching session. -->

# Composure live coaching

The owner authorized this milestone on 29 October 2026. Deliver an explicit Mac Start/Stop session,
temporary speech context, occasional useful on-device cues, and a floating native panel.
Keep the existing Debug capture check available. Preserve the owner's unrelated Xcode project changes.

## Design and interfaces

Use an Adapter at each Apple framework boundary. Native speech and model adapters implement small core
contracts so that synthetic tests can verify cancellation, privacy, and cue timing without capture.
Use the existing Observation mechanism for UI state. No additional GoF pattern is required for bounded
values, buffer operations, or cue rules. A separate model protocol permits controlled test doubles and
shares the existing model adapter's single work slot with Prepare.

Core additions under `Packages/ComposureCore/Sources/ComposureCore`:

- `SpeakerRole.swift`, `SpeechChannel.swift`, and `TranscriptEvent.swift`: validated transient source,
  audio start/end times, partial/final state, identity, and bounded text.
- `ConversationBuffer.swift`: replace partial revisions, preserve final results, sort by audio time,
  prune after 120 seconds, and enforce count and byte limits.
- `CueKind.swift`, `CuePriority.swift`, `CueProposal.swift`, `CoachCue.swift`, `CuePolicy.swift`, and `CueArbiter.swift`:
  validate instructions, accept recent evidence, show one cue, expire cues, and suppress repetition.
- `LiveCoachingInput.swift` and `LiveCoachingModel.swift`: bounded recent finalized context, objective,
  explicit style, and saved profile. `evaluate(_:) async throws -> CueProposal?` returns no action normally.
- `LiveTranscriptionSource.swift`: main-actor `start(localeIdentifier:receive:failure:) async throws`,
  synchronous `cancelStart()`, and `stop() async -> Bool` for confirmed native cleanup.
- `LiveSessionState.swift`, `LiveSessionError.swift`, and `LiveSessionCoordinator.swift`: explicit lifecycle,
  one model operation, cancellation, stale-session rejection, periodic pruning, and immediate content clearing.

Native additions under `Sources/ComposureModels`:

- `MacMeetingAudioSource.swift`, `MeetingSpeechChannel.swift`, `MeetingAudioSink.swift`, and
  `MeetingAudioHealth.swift`, `MeetingSpeechTiming.swift`, and `MeetingCaptureLifecycle.swift`: picker-selected application audio, separate microphone input, two analyzers,
  bounded audio streams, shared host-clock mapping, and fixed failures.
- `GeneratedLiveCue.swift`, `LiveCueAction.swift`, `LiveSituation.swift`, `GeneratedLiveSituation.swift`,
  `GeneratedLiveInstruction.swift`, `LiveCoachingPrompt.swift`, and `AppleFoundationCoachingModel+Live.swift`:
  classify the situation before generating personalized wording. Use fresh tool-free guided generation,
  independent validation, prompt-injection boundaries, and bounded context. Reuse the existing narrow
  `PreparationContextRules.hasProtocolOverride` signals. These signals do not prove general injection resistance.
- Reuse the tested converter, picker, and native-error adapters from the development check on Mac Release
  builds too. These helpers remain private to the native module. Keep the Debug experiment's time limit.

App additions under `Apps/macOS`:

- `MacLiveCoachView.swift`: visible readiness, transient optional objective, session style, explicit Start/Stop,
  clear active/error states, and inline cue display. No transcript view or session history.
- `MacLiveCoachComposition.swift`: one app-owned source and coordinator across windows, shared model slot.
- `MacCuePanel.swift`, `NonActivatingCuePanel.swift`, and `MacCuePanelView.swift`: non-activating native floating panel with Stop always available.
- `ComposureMacDelegate.swift`: finish normal session cleanup before application termination.
- `UITestLiveSource.swift` and `UITestLiveModel.swift`: synthetic Debug-only fixtures.
- Update `MacRootView.swift`, `ComposureMacApp.swift`, `ReadinessComposition.swift`,
  `UITestReadinessProvider.swift`, `CoachingSettingsView.swift`, and developer-check copy.
- Update `Composure.entitlements` and Mac Release project metadata for explicit microphone use.
  Mobile capture remains a later milestone. Native model/core contracts compile for all supported platforms.

Tests under the matching package test directories:

- `ConversationBufferTests.swift`: revisions, finalized stability, ordering, time bounds, byte/count limits, cleanup.
- `CueArbiterTests.swift`: expiry, cooldown, duplicate suppression, stale evidence, frequency caps, language limits.
- `LiveSessionCoordinatorTests.swift`, `TestLiveTranscriptionSource.swift`, and `TestLiveCoachingModel.swift`:
  passive initialization, explicit lifecycle, duplicate Start, stopped/failed cleanup, late events/results,
  model cancellation, quiet failures, and unconfirmed native Stop.
- `LiveCoachingModelTests.swift` and `LiveCoachingEvaluationTests.swift`: bounded prompt/schema, independent output validation, and injection fixtures.
- `MeetingAudioHealthTests.swift`, `MacMeetingAudioSourceTests.swift`, and `MeetingSpeechTimingTests.swift`: native timing and bounded health state.

Add `Tests/MacUI/LiveCoachUITests.swift`, a Mac UI-test target in `project.pbxproj`, and its shared Mac scheme TestAction.

Update `README.md`, `PROJECT.md`, `ADDITIONAL.md`, `CHANGELOG.md`, `CONVERSATION.md`,
`specs/composure.status.md`, and the relevant graph concepts/entities/decision/history records.

## Behavior and limits

The first session uses the tested Mac/Chrome capture path. The native picker selects an application.
Composure reads no screen output, writes no audio or transcript, and sends no conversation content off-device.
The buffer holds at most 120 seconds, 128 events, and 32 KiB of speech text. Model input selects a smaller
recent finalized subset. Partial text never triggers generation. No displayed transcript is added.

One fresh model request runs at a time. Opportunities are at least three seconds apart. The cooperative
generation deadline is six seconds. Results must cite recent finalized input and pass independent validation.
Cues expire after eight seconds. Default cooldown is 20 seconds and same-type suppression is 90 seconds.
The profile adjusts frequency and semantic focus. Invalid, unavailable, late, or refused model output gives no cue.

Both source streams receive timestamps on the same host clock. The initial speaker attribution is unknown
because the owner's speaker route can leak meeting audio into the microphone. Do not enable interruption,
rapid-response, or speaking-duration cues until route testing establishes reliable speaker separation.
Semantic instructions must not infer emotions, personality, honesty, competence, or participant identity.

Mac sessions continue when Chrome becomes active. Stop on explicit Stop, owning view closure/navigation,
sleep, screen sleep/lock, session deactivation, route/source changes, or capture failure. Clear context and
displayed cues immediately. Block restart until native capture stop is confirmed. Do not resume automatically.

## Verification sequence

Write and run failing behavioral tests before each core or native behavior change. Commit and push the
verified core, then the usable native integration. Run package tests, all native target builds including Mac
Release, source-style checks, and the full repository check. Use synthetic speech/model fixtures without
real meeting content. Add controlled on-device promotion and injection evaluations where the local model allows.

The owner tests the signed Mac app in Meet. Verify relevant cues and deliberate silence, focus retention,
Stop, repeated Start/Stop, and no remaining microphone indicator. Physical route, long-session, offline,
and persistent-content searches remain explicit acceptance evidence, not claims based on compilation.


## Implementation evidence on 30 October 2026

The first verified core checkpoint reached origin/main as 20aee61. Native integration now builds for
Mac Debug and Release and both mobile compilation destinations. Mac live capture is available in Debug
and Release. The separate development check remains Debug-only through `--development-audio-check`.

The original one-pass live schema overused the profile's curiosity priority. Controlled evaluation exposed
a generic manager cue and unsuitable cues for instruction-override content. The revised pipeline classifies
the speech before personalization, screens narrow known override signals, then generates a bounded imperative.
Low-confidence decisions remain silent. Speaker identity remains unknown. Direct-answer cues join
interruption, response timing, and speaking duration as disabled until attribution has supporting evidence.

The public model adapter passed both promotion fixtures, four ordinary remarks, and three override fixtures
on the development Mac. Observed positive generations took about one to two seconds. These are synthetic
model measurements, not end-to-end speech latency or broad quality evidence.

Two ad-hoc-signed Mac UI journeys passed. They verify explicit Start, a synthetic cue, Stop clearing the
objective and panel, navigation cleanup, and cue display while Finder keeps focus. The initial unsigned UI
runner failed before bootstrapping. Ad-hoc signing resolved that infrastructure problem.
Visual inspection confirmed readable native controls and one short floating cue.

The new production source was not used for a real microphone call by the agent. Actual Meet quality,
route separation, long physical sessions, offline transcription, and post-Stop content searches remain owner gates.
No application archive, upload, store submission, website deployment, or message to another person occurred.

Final checks passed the full repository suite, 112 core tests, and the native package suite with 57 declarations
and five opt-in skips. The explicit live-model evaluation passed separately. Semantic cues use normal priority.
High-priority detector replacement remains outside this initial role-neutral slice.

The panel starts near the top center of the active screen and can be moved by dragging its background.
The owner's object version and signing settings remain outside the isolated project commit draft.

## Objective editability follow-up on 30 October 2026

The owner reported one cue during about 20 to 30 seconds of speaking and an objective field that could not be edited.
The current view disables the entire setup section while a session is active. The earlier UI test typed an
objective but checked only that Stop cleared the field. It did not verify that typing changed the value.

First strengthen `Tests/MacUI/LiveCoachUITests.swift` to assert the exact text before Start and after Stop.
Check `Apps/macOS/MacLiveCoachView.swift` for field affordance, focus, and disabled-state explanations.
Keep capture and model processing in their existing services. No GoF pattern is required for this view correction.
Preserve the fixed objective during an active session unless the owner requests live editing.
Update the README, status, conversation, changelog, and history with the actual observation and verified correction.

The owner clarified that the field was certainly uneditable after the conversation, but was unsure about
before Start. The strengthened baseline UI test passed without a source change. It confirmed exact text
entry before Start and after Stop. The active-session lock is intentional. The view now uses a separate
label and native bordered field, plus an active-session explanation that pauses do not end coaching.
The test also checks the active lock. Capture, model inputs, storage, and objective limits are unchanged.

Verification passed both synthetic Mac UI journeys, both Mac build destinations, the full repository suite,
source-style checks, and patch-whitespace checks. Visual inspection confirmed a readable bordered input
and entered text. No microphone capture was started by the agent during this follow-up.
