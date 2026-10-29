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
- `CueKind.swift`, `CueProposal.swift`, `CoachCue.swift`, `CuePolicy.swift`, and `CueArbiter.swift`:
  validate instructions, accept recent evidence, show one cue, expire cues, and suppress repetition.
- `LiveCoachingInput.swift` and `LiveCoachingModel.swift`: bounded recent finalized context, objective,
  explicit style, and saved profile. `evaluate(_:) async throws -> CueProposal?` returns no action normally.
- `LiveTranscriptionSource.swift`: main-actor `start(localeIdentifier:receive:failure:) async throws`,
  synchronous `cancelStart()`, and `stop() async -> Bool` for confirmed native cleanup.
- `LiveSessionState.swift`, `LiveSessionError.swift`, and `LiveSessionCoordinator.swift`: explicit lifecycle,
  one model operation, cancellation, stale-session rejection, periodic pruning, and immediate content clearing.

Native additions under `Sources/ComposureModels`:

- `MacMeetingAudioSource.swift`, `MeetingSpeechChannel.swift`, `MeetingAudioSink.swift`, and
  `MeetingAudioHealth.swift`: picker-selected application audio, separate microphone input, two analyzers,
  bounded audio streams, shared host-clock mapping, and fixed failures.
- `GeneratedLiveCue.swift`, `LiveCoachingPrompt.swift`, and `AppleFoundationCoachingModel+Live.swift`:
  fresh tool-free guided generation, independent validation, prompt-injection boundaries, and bounded context.
- Reuse the tested converter, picker, and native-error adapters from the development check on Mac Release
  builds too. These helpers remain private to the native module. Keep the Debug experiment's time limit.

App additions under `Apps/macOS`:

- `MacLiveCoachView.swift`: visible readiness, transient optional objective, session style, explicit Start/Stop,
  clear active/error states, and inline cue display. No transcript view or session history.
- `MacLiveCoachComposition.swift`: one app-owned source and coordinator across windows, shared model slot.
- `MacCuePanel.swift` and `MacCuePanelView.swift`: non-activating native floating panel with Stop always available.
- Update `MacRootView.swift`, `ComposureMacApp.swift`, and shared readiness/settings copy as needed.
- Update `Composure.entitlements` and Mac Release project metadata for explicit microphone use.
  Mobile capture remains a later milestone. Native model/core contracts compile for all supported platforms.

Tests under the matching package test directories:

- `ConversationBufferTests.swift`: revisions, finalized stability, ordering, time bounds, byte/count limits, cleanup.
- `CueArbiterTests.swift`: expiry, cooldown, duplicate suppression, stale evidence, frequency caps, language limits.
- `LiveSessionCoordinatorTests.swift`, `TestLiveTranscriptionSource.swift`, and `TestLiveCoachingModel.swift`:
  passive initialization, explicit lifecycle, duplicate Start, stopped/failed cleanup, late events/results,
  model cancellation, quiet failures, and unconfirmed native Stop.
- `LiveCoachingModelTests.swift`: bounded prompt/schema, independent output validation, and injection fixtures.
- `MeetingAudioHealthTests.swift` and `MeetingSpeechTimingTests.swift`: native timing and bounded health state.

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
