<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 41bd4db9-7fb6-4963-83c1-a467ea1ee1af
Created: 2026
-->

<!-- AGENT: Reviews Composure requirements and defines the first executable foundation slice. -->

# Composure foundation and specification review

Reviewed on 24 October 2026. The normative implementation specification remains authoritative.

## Assessment

The product scope and privacy rules support an incremental implementation. No backend or new dependency is needed.
The architecture separates capture, speech, coaching, arbitration, and platform presentation appropriately.
The implementation plan describes a full release program, including physical-device and meeting-hardware checks.
Compilation alone cannot satisfy those release gates.

The owner confirmed Mac, iPhone, and iPad support, with minimum operating system versions of 26.
Remote setup must stop if separate microphone capture is unavailable.
Available test hardware includes an M1 iPad Pro, M5 MacBook Pro, M4 Mac mini, M4 Mac Studio,
iPhone 12 mini, and iPhone 17 Pro. Apple Intelligence readiness remains a runtime check.
The owner later added an iPad Air 3 and iPhone 14 Pro. Their OS versions are unknown.
The owner explicitly accepted the four safety controls and early dual-stream testing in this review.

## Findings and implementation controls

1. In-person speech has unknown speakers. Cues must not assert that the user interrupted or received a question.
   Silence is preferable when the intended recipient is unclear.
2. Time limits alone do not bound memory. Bound event counts, text bytes, stream queues, and model input size too.
   Create bounded model requests without an accumulating meeting-long model session.
3. Treat preparation text and speech as untrusted model input. Keep application instructions separate.
   Validate structured output independently and add synthetic prompt-injection cases.
4. A timestamp alone cannot measure interruption duration. Preserve audio start/end times and a common session clock.
   Replace partial revisions rather than appending duplicate speech. Stop must invalidate late results from previous sessions.
5. Specify stop-and-clear behavior for mobile backgrounding, source loss, sleep, and closing the last capture indicator.
   Prevent system restoration and app-switcher snapshots from retaining sensitive preparation or live content.
6. Test two simultaneous analyzers and shared microphone access early, before extensive remote feature work.
   Check the 26 deployment baseline even when the development SDK offers newer APIs.
7. Define measured coaching-quality thresholds before the model evaluation milestone.
   The two-second cue target and analysis cadence require device measurements, not a promised response time.
8. Keep the source path at src/composure. Enable the native profile component before creating application source.
   Use tests before implementation, as required by the shared workflow.

Apple documents simultaneous-analysis resource limits and runtime speech-device support:
[SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer) and
[SpeechTranscriber](https://developer.apple.com/documentation/speech/speechtranscriber).
Apple also documents [model input boundaries](https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output)
and [stateful model sessions](https://developer.apple.com/videos/play/wwdc2025/301/).
These sources support the controls above. They do not prove Composure's compatibility.

## First slice

Create two native application targets and one local Swift package. Provide native navigation and clear feature placeholders.
Do not activate capture, model inference, persistence, or permissions in this foundation slice.
Introduce domain contracts when behavior first needs them, rather than adding unused service implementations.
This splits Phase 0 into an executable foundation and later pipeline contracts. It does not complete Phase 0's device gate.

Use a narrow logging facade that accepts an event enum and bounded numeric metadata.
Use a pure session transition policy that tests valid start, stop, failure, and retry sequences.
Keep SwiftUI views thin. Keep all session rules and logging contracts in ComposureCore.

No pattern required - simple function/class suffices for the initial navigation and value types.
The session enum expresses the State pattern without a class hierarchy.
The logging facade isolates the platform sink and prevents arbitrary content strings at call sites.
Both choices reduce coupling without a dependency framework.

## Files

Create these application and package files under src/composure:

- Composure.xcodeproj/project.pbxproj
- Composure.xcodeproj/xcshareddata/xcschemes/Composure Mac.xcscheme
- Composure.xcodeproj/xcshareddata/xcschemes/Composure Mobile.xcscheme
- Apps/macOS/ComposureMacApp.swift
- Apps/macOS/MacRootView.swift
- Apps/macOS/Composure.entitlements
- Apps/iOS/ComposureMobileApp.swift
- Apps/iOS/MobileRootView.swift
- Apps/Shared/FeaturePlaceholder.swift
- Apps/Shared/AppSection.swift
- Apps/Shared/ApplicationDiagnostics.swift
- Apps/Shared/PrivacyInfo.xcprivacy
- Packages/ComposureCore/Package.swift
- Packages/ComposureCore/Sources/ComposureCore/CoachSessionState.swift
- Packages/ComposureCore/Sources/ComposureCore/SessionError.swift
- Packages/ComposureCore/Sources/ComposureCore/SessionLifecycle.swift
- Packages/ComposureCore/Sources/ComposureCore/DiagnosticEvent.swift
- Packages/ComposureCore/Sources/ComposureCore/DiagnosticMetadata.swift
- Packages/ComposureCore/Sources/ComposureCore/DiagnosticLogger.swift
- Packages/ComposureCore/Tests/ComposureCoreTests/SessionLifecycleTests.swift
- Packages/ComposureCore/Tests/ComposureCoreTests/DiagnosticLoggerTests.swift
- build.sh
- clean.sh
- README.md

Modify test.sh and scripts/check-source-style.sh to include Composure checks.
Create test/composure-scripts.bats and update related root command fixtures.
Update PROJECT_PROFILE.md through configure.sh and regenerate the managed AGENTS.md block.
Update PROJECT.md, ADDITIONAL.md, README.md, CONVERSATION.md, CHANGELOG.md, specs/composure.status.md,
agentknowledge/concepts.yaml, agentknowledge/entities.yaml, agentknowledge/decisions.yaml, and agentknowledge/history.jsonl.
Update the normative specification with the owner's confirmed platform and remote-failure decisions.

## Interfaces

- SessionLifecycle.state: CoachSessionState, read-only outside the type.
- SessionLifecycle.transition(to: CoachSessionState) throws: rejects invalid transitions without changing state.
- CoachSessionState: idle, checkingReadiness, requestingPermissions, selectingAudioSource, starting,
  listening, stopping, failed(SessionError).
- DiagnosticLogger.record(_: DiagnosticEvent, metadata: DiagnosticMetadata): forwards approved values only.
- DiagnosticMetadata.init(itemCount: Int): bounds counts to a documented range.
- ApplicationDiagnostics: creates the native unified-log sink at the application boundary.

## Sequence and acceptance

1. Record specification findings and confirmed owner decisions.
2. Enable the planned native component through the configurator preview and apply commands.
3. Write shell routing tests and package behavior tests before their implementations.
4. Observe the expected failures, then implement the foundation.
5. Run package tests, source checks, and both application builds, including simulator and device compilation.
6. Run the full repository validation command.
7. Inspect native navigation where execution tools permit it.
8. Record physical-device checks separately from builds, then create a local commit.

The next slice implements onboarding, the Coaching Profile, and Prepare.
Physical-device launch checks remain required before declaring the Phase 0 gate complete.

## Follow-up: Match package and application architectures

The owner reported an unresolved ComposureCore import in ApplicationDiagnostics.swift.
The detailed log showed an x86_64 application compile using an arm64-only package module.
Fresh generic Mac builds passed, but the active arm64 Mac destination reproduced that exact failure.
The application omitted ONLY_ACTIVE_ARCH in Debug. Swift packages use the active architecture for this destination.

No pattern required - simple function/class suffices. No runtime interface or application layer changes are needed.
Set the project's Debug configuration to ONLY_ACTIVE_ARCH=YES and make Release's active-architecture setting explicit.
The owner then confirmed that Composure must support Apple silicon Macs only.
Set ARCHS=arm64 for both Mac configurations. Release builds must also contain only arm64 code.
Add active-destination and generic arm64 Mac checks to the component builder.
Use ONLY_ACTIVE_ARCH=NO for generic builds so package and app architectures remain aligned.

Change these files:

- src/composure/Composure.xcodeproj/project.pbxproj: align Debug architecture selection and require arm64 for Mac targets.
- src/composure/build.sh: build the active and generic Mac destinations with arm64 package and application code.
- test/composure-scripts.bats: require both Mac build paths and verify generic architecture overrides.
- src/composure/README.md: explain the two Mac checks and the retry procedure.
- src/composure/product-specification.md, implementation-specification.md, and implementation-plan.md: record Apple silicon scope.
- PROJECT.md and agentknowledge/decisions.yaml: record the authoritative hardware choice.
- specs/composure.status.md: record the reproduced failure and corrected build results.
- CONVERSATION.md and CHANGELOG.md: record the report, correction, and verification.
- agentknowledge/history.jsonl: append the outcome.

First reproduce the active-destination compiler error and the missing command coverage in failing checks.
Then change the Debug setting and rerun the same failing destination without removing its build directory.
Verify a second fresh active build, arm64 Release build, and mobile variants.
Inspect the Mac application binary to confirm that it contains only arm64 code.
Run the core suite, full repository checks, and source-style checks before committing and pushing.
