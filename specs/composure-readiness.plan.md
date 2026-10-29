<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: c7a54864-4a36-4e92-b1a5-5400472e91cf
Created: 2026
-->

<!-- AGENT: Defines speech setup and the early remote-capture experiment before implementation. -->

# Speech readiness and early capture check

The owner authorized this slice after accepting the Prepare correction.
Implement Phase 3, then provide the early Mac feasibility experiment from Phase 4.
Keep Apple silicon Macs and iPhone/iPad on OS 26 or later.

## Design and contracts

Use an Adapter for Apple speech assets and native permission APIs behind ReadinessProvider.
The adapter isolates system effects and permits controlled tests without downloads or permission prompts.
Use an observable main-actor ReadinessCoordinator for app-wide setup state and native views for rendering.
No additional pattern is required. Keep state enums and mapping functions direct.

Public core contracts:

- SpeechAssetState describes unchecked, unavailable, unsupported locale, needs setup, downloading, ready, or unknown status.
- CapturePermissionState describes unknown, not requested, allowed, denied, restricted, not granted, or not applicable.
- DeviceReadiness holds those states, the existing ModelReadiness, and the resolved English locale identifier.
- ReadinessProvider.snapshot() async returns DeviceReadiness without requests, downloads, or capture.
- ReadinessProvider.setUpSpeech(progress:) async throws performs explicitly requested asset setup.
- The progress callback accepts an optional fraction and never carries meeting data.
- ReadinessCoordinator.refresh() and setUpSpeech() serialize UI actions and expose fixed errors and bounded progress.

AppleReadinessService selects a supported English locale and the same time-indexed progressive transcriber configuration needed by live speech.
Only explicit setup obtains an installation request. Read-only status must not reserve or download assets.
Recheck installed status after setup. A returned request or successful method alone does not establish readiness.
Apple manages shared assets and can resume downloads later. Do not promise that cancelling app work cancels those downloads.
Read microphone authorization without requesting it. A failed Mac screen-capture preflight means not granted, not proof of denial.
The Settings status screen checks these prerequisites but must not claim that live coaching is implemented.
No preferences schema changes, audio, transcript, model generation, or meeting persistence belong to speech setup.
Use fixed diagnostic events and controlled error categories only.

## Files

Add under Packages/ComposureCore/Sources/ComposureCore:
SpeechAssetState.swift, CapturePermissionState.swift, DeviceReadiness.swift, ReadinessProvider.swift,
ReadinessError.swift, and ReadinessCoordinator.swift. Extend DiagnosticEvent.swift.
Add AppleReadinessService.swift and AppleReadinessMapping.swift under Sources/ComposureModels.
Add ReadinessCoordinatorTests.swift and TestReadinessProvider.swift under Tests/ComposureCoreTests.
Add SpeechReadinessTests.swift under Tests/ComposureModelsTests.

Add Apps/Shared/OnDeviceReadinessView.swift, ReadinessComposition.swift, and UITestReadinessProvider.swift.
Update CoachingSettingsView.swift, both application entry points, and both root views to share readiness state.
Add Tests/UI/ReadinessUITests.swift and the required Xcode file references.
Preserve the owner's unrelated project formatting, team, and signing changes in the working tree and exclude them from commits.

The Mac feasibility implementation will add a separate developer-only audio check, its bounded stream/analyzer helpers,
unit coverage, and an explicit manual test procedure. Record the exact files and API choices before that implementation.
Do not start real capture from automated tests or claim hardware compatibility without observed evidence.
Stop setup when a separate microphone stream or a second analyzer cannot be established.

Update src/composure/README.md, PROJECT.md, ADDITIONAL.md, CHANGELOG.md, CONVERSATION.md,
specs/composure.status.md, and the knowledge concepts, entities, decisions, and append-only history.

## Verification

Observe new core contract tests failing before implementation.
Test passive checking, explicit setup, progress bounds, failure recovery, duplicate action prevention,
cancellation, and successful setup that still reports downloading rather than ready.
Test every native asset and permission mapping without causing prompts or downloads.
Inspect native speech status on this Mac without installing assets automatically.
Test native Settings setup and retry using an isolated Debug provider on iPhone and iPad simulators.
Build active and generic arm64 Mac, mobile simulator, and physical mobile variants.
Run the complete repository suite and source checks before committing and pushing each verified slice.
Actual asset installation, offline speech operation, and remote compatibility require their own explicit checks.

## Speech-readiness results

Core and native contract tests failed before implementation. The final core passed 77 tests.
The native adapter has five new mapping tests plus a separately enabled passive speech-status probe.
That probe reported en_US assets needing setup and no change to asset reservations on this Mac.
The full onboarding, Prepare, and setup journeys passed on phone and iPad simulators running OS 26.5.
The setup fixture verifies failure and retry without native downloads or permission requests.
All native builds, repository regressions, and source checks passed. Actual installation and offline speech remain open.

References: [Apple asset management](https://developer.apple.com/documentation/speech/assetinventory),
[installation behavior](https://developer.apple.com/documentation/speech/assetinstallationrequest/downloadandinstall()).

## Early Mac experiment implementation

Provide a Debug-only Live Coach audio check in the existing Mac app.
Start must be explicit, speech assets must already be installed, and the user must select one app through the system sharing picker.
Capture microphone and selected-app audio as separate ScreenCaptureKit output types.
Use a fixed microphone device, stop on route changes, and require both streams before showing successful sample delivery.
Prepare two SpeechAnalyzer instances with separate time-indexed progressive transcribers and bounded input streams of eight buffers each.
Copy bounded PCM buffers, convert to a compatible format, and preserve timestamps on the stream's common host clock.
Drain recognition results without reading, displaying, logging, or retaining transcript text.
Stop after 20 seconds, on explicit Stop, when the view closes, or on relevant workspace lifecycle events.
If capture cannot stop cleanly, keep the Stop action and report the failure instead of presenting an idle state.
No recording output, audio file, transcript storage, or cloud model belongs to the experiment.

Add CaptureCheckChannel.swift, CaptureCheckFailure.swift, CaptureCheckMetrics.swift, and CaptureCheckState.swift under the pure core.
Add CaptureCheckMetricsTests.swift under its tests.
Add MacCaptureCheck.swift, CaptureCheckPicker.swift, CaptureCheckAudioSink.swift,
CaptureCheckSpeechChannel.swift, and CaptureCheckAudioConverter.swift under ComposureModels, guarded for Debug macOS.
Add CaptureCheckErrorMapping.swift and its unit tests to preserve microphone failures and explicit stop confirmations.
Add CaptureCheckAudioConverterTests.swift and passive MacCaptureCheckTests.swift under native adapter tests.
Add Apps/macOS/MacCaptureCheckView.swift and ComposureDebug.entitlements. Update MacRootView.swift.
Add the required Mac source references, Debug microphone usage text, and Debug-only audio-input entitlement in the project.
Keep Release capture behavior and entitlements unchanged. Preserve owner project changes through the same selective staging procedure.

Core metrics contracts record a channel's bounded buffer count and timing and reject invalid, decreasing, or excessive input.
Metrics report missing microphone or meeting streams at setup deadlines. They never imply that a meeting app still receives microphone audio.
The developer must verify microphone sharing, routing, and stream alignment during a synthetic test call.
Document the exact device, OS, app, route, result, and unresolved cases. Do not treat compilation or synthetic tests as hardware proof.

## Experiment implementation results

The Debug Mac check and all native variants compile. A separate Release Mac build also passed.
The built Debug app has microphone usage text. The Release app has none and retains the original entitlement file without audio input.
Core tests cover missing streams, invalid or decreasing timing, and buffer quotas.
Native tests cover bounded PCM conversion, continuous resampled timing, passive initialization, cancellation-safe cleanup, and error meanings.
The package passed 84 core tests and 37 native unit tests. Four model/speech evaluations remain opt-in.
No real capture, actual microphone sharing, two-analyzer processing of live speech, or offline speech operation was run.
The developer procedure in the component README defines the remaining physical-device check.

## Usability correction and owner observation

The owner reported a disabled Start action caused by speech assets still needing setup or downloading.
Add the existing readiness component inline, expose a direct refresh, and put Start/Stop before the counters.
Clarify that the screen reports audio and recognition events without coaching feedback.
This rendering change modifies MacCaptureCheckView.swift, the component README, and the repository records.
No new pattern or public interface is required. The existing setup coordinator and capture guards remain authoritative.
Validate the native builds and repository/source checks. Reuse the tested setup component without adding tests that mirror UI composition.

The owner subsequently confirmed that both recognition-event counters increased and Chrome/Meet retained microphone access.
The test used the MacBook Pro's built-in microphone and speakers. The host reports macOS 26.6.2.
The basic early feasibility gate is satisfied for this one configuration based on the owner's report.
Accuracy, echo separation, precise alignment, other routes, mobile capture, and long sessions remain unverified.
