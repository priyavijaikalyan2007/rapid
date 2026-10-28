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
