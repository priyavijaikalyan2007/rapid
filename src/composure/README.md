<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: f6dced28-f65c-44dd-b0da-e73996a9e0a9
Created: 2026
-->

<!-- AGENT: Describes the executable Composure foundation, local commands, and remaining feature gates. -->

# Composure

Composure is a private conversation coach in development for Mac, iPhone, and iPad.
The application provides privacy onboarding, saved profile settings, and private conversation preparation through native controls.
Settings also checks device prerequisites and offers explicit speech-asset setup.
Prepare uses an on-device model for situation-specific coaching, with labeled profile-based guidance when generation is unavailable.
Preparation input and results remain in memory. Mac Live Coach now supports explicitly started remote sessions and occasional on-device cues.
Mac Debug and Release builds capture separate microphone and selected-application audio after Start. Mobile live capture remains planned.
A separate Debug audio check remains available for development.
Opening the app, checking readiness, and setting up speech do not request microphone access or start listening.

Read the [normative specification](implementation-specification.md) for requirements.
Read the [implementation plan](implementation-plan.md) for the full release sequence.
Read the [foundation review](../../specs/composure-foundation.plan.md) and
[status record](../../specs/composure.status.md) for current work and verification limits.

## Local development

Use a full Xcode installation on an Apple silicon Mac.
The targets require macOS 26 or iOS/iPadOS 26 or later. Composure's Mac application supports arm64 only.
The shared package uses Swift 6 and contains no external dependencies.
The build script selects /Applications/Xcode.app/Contents/Developer when DEVELOPER_DIR is unset.
All generated outputs remain under this component's ignored build directory.

Run core tests and compile all application variants from the repository root:

```sh
./src/composure/build.sh all
```

Run core and native model-adapter tests:

```sh
./test.sh composure
```

Compile the Mac target for the active Apple silicon destination and a generic arm64 destination:

```sh
./src/composure/build.sh macos
```

Compile both simulator and physical-device mobile variants:

```sh
./src/composure/build.sh ios
```

Remove generated component output:

```sh
./src/composure/clean.sh
```

The shared package tests lifecycle transitions, typed preferences, preparation, recovery, and content-safe diagnostics.
Its separate ComposureModels target isolates Apple Foundation Models from the pure core.
The applications log fixed lifecycle events without profile values or meeting content.
One versioned UserDefaults record stores only coaching choices and app preferences.
Corrupt or unsupported records require explicit recovery. Operating-system backups can include saved preferences.
Both Mac configurations enable App Sandbox and microphone input. They have no network entitlement.
Microphone use requires explicit Start. Both configurations include a microphone usage description.
Both Debug and Release Mac configurations build arm64 applications.
Unsigned builds do not verify signed sandbox behavior or installation on physical mobile devices.

Debug builds use the active architecture, matching Swift package behavior for Xcode's My Mac destination.
Generic command-line builds set matching app and package architectures explicitly.
If an open Xcode project retains the old architecture settings, reopen the project before building again.

## Device launch check

1. Open Composure.xcodeproj in Xcode.
2. Select the Composure Mac or Composure Mobile scheme.
3. Select your Mac, connected iPhone, or connected iPad.
4. Select your development team if Xcode requires device signing.
5. Run the application.
6. Complete the four setup steps.
7. Check each navigation destination.

Expect privacy onboarding, editable Settings, Prepare, and Mac Live Coach controls. Mobile Live Coach remains a feature-status screen.
Expect no microphone or speech permission prompts.
Record the device model, OS version, and launch result in the status record.
No build command uploads or publishes the application.

## What to test now

Use the [Mac live coaching procedure](#mac-live-coaching-check) for the new milestone.
The following foundation checks cover onboarding, saved preferences, preparation, and native layout.
Prepare works without Apple Intelligence through profile-based guidance.
Start with one Mac, the iPhone 17 Pro, and the M1 iPad Pro if each runs OS version 26 or later.
Other supported devices can follow. Record older OS versions without changing deployment targets or updating devices automatically.

1. Run ./src/composure/build.sh all from the repository root.
   Expect core and model-adapter tests to pass, plus all unsigned platform builds.
   Opt-in live-model evaluations are skipped by default.
2. Run the Composure Mac scheme on one Mac through Xcode.
   Expect onboarding on the first launch, then Home, Prepare, Live Coach, and Settings in the sidebar.
3. Run the Composure Mobile scheme on a physical iPhone through Xcode.
   Expect onboarding on the first launch, then Prepare, Live Coach, and Settings tabs.
4. Run the Composure Mobile scheme on a physical iPad through Xcode.
   Expect the same destinations in a layout that fits the available window.
5. Use Back and Continue during setup.
   Expect each disclosure to remain readable and profile choices to remain when you return to them.
6. Change profile choices before you select Finish setup.
   Expect setup to complete without an audio permission prompt.
7. Change a profile choice in Settings.
   Expect an unsaved-change status until you select Save or Discard changes.
8. Select Save.
   Expect the saved status and your selected values after you quit and relaunch the app.
9. Select Reset coaching profile and cancel the confirmation.
   Expect no change to the profile.
10. Confirm Reset coaching profile.
    Expect default profile values, preserved session defaults, and no repeat of onboarding.
11. Open Live Coach.
    Expect the Mac session to show Not listening before Start. Mobile shows its feature-status screen.
12. Rotate each mobile device.
   Expect readable text and accessible navigation in portrait and landscape.
13. Resize the Mac and iPad windows where supported.
   Expect the native layout to remain usable.
14. Check larger text, VoiceOver, and Mac keyboard navigation.
    Expect labeled controls, readable choices, and accessible Save, Back, and Continue actions.

Report the device model, OS version, launch result, layout issues, and any permission prompt or crash.
Mac audio capture, speech recognition, and cue quality use the separate live procedure below.

## Prepare checks

1. Open Prepare on the Mac, iPhone, or iPad.
   Expect a truthful model-readiness message and an empty conversation form.
2. Enter a synthetic topic, such as “Give constructive feedback.”
3. Select Prepare conversation.
   Expect Objective, Watch For, Questions to Ask, If Challenged, and Keep in Mind.
4. Check the preparation source.
   Expect On-device preparation when the model runs, or Profile guidance with a reason when it does not.
5. Select Edit inputs.
   Expect the previous input to remain available.
6. Select Clear.
   Expect the input and results to disappear.
7. Change an important focus in Settings and select Save.
8. Prepare another synthetic conversation.
   Expect preparation to consider the saved profile. Unsaved Settings edits must not change preparation.
9. Start model preparation and select Cancel when the action is available.
   Expect generation to stop without a late result. A previous request may need time to finish cancellation.
10. On iPhone or iPad, switch apps during preparation.
    Expect a privacy cover in the app switcher and cleared preparation after you return.
11. Quit and relaunch the application.
    Expect saved profile settings and empty preparation fields.

The model generates bounded language for the supplied situation and role. Fixed phrases are used for fallback.
Generated advice can still be unsuitable or contain unsupported assumptions. Check whether the guidance fits your conversation.
For promotion conversations, check whether questions and scripts use the correct role and avoid unjustified promises.
Compare receiving a promotion decision with explaining one to a direct report.
The recipient should receive help seeking feedback and managing their own response.
The manager should receive help explaining expectations, checking understanding, and discussing support without promising a future decision.
The app screens for embedded instruction overrides. This screening does not guarantee complete resistance to prompt injection.
On older systems, conservative context budgeting can select profile guidance for longer input.
Memory-only storage does not guarantee that Swift or the operating system erases every memory copy.

Run the opt-in live-model evaluations using synthetic data only:

```sh
COMPOSURE_EVALUATE_MODEL=1 ./test.sh composure
```

The evaluations check readiness before generating. If the model is unavailable, they cannot verify model quality.
They cover 20 synthetic topics, a paired role regression, and five injection fixtures.
The question-diversity check catches repeated pairs. Human review must still assess whether each suggestion is useful and uses the correct voice.

## Speech readiness checks

1. Open Settings and scroll to Privacy and on-device status.
2. Select Check device readiness.
   Expect speech-asset status, the resolved English locale, model availability, and current capture permission states.
   Expect no capture permission prompt or audio capture.
3. If speech needs setup, select Set up speech.
   Expect Apple-managed asset installation and progress when available.
4. If setup fails, check the connection and available storage before trying again.
   Apple may continue or resume its download later. Refresh the status before retrying.
5. Wait for Speech model to show Ready.
   Ready means the configured speech assets are installed. Start also requires an available on-device coaching model.
6. Relaunch the app and refresh the status.
   Expect the system's current asset state rather than a saved success flag.

The app prefers a supported English locale matching the device and otherwise selects a supported English fallback.
Apple shares and manages these speech assets across applications. Composure does not store or upload meeting content during setup.
A Mac screen-capture preflight that returns false appears as Not granted. It does not prove that permission was denied.
Capture permissions will be requested only through an explicit capture start action.

Inspect actual speech status without reserving or downloading assets:

```sh
COMPOSURE_EVALUATE_SPEECH=1 ./test.sh composure
```

The simulator setup journey uses an isolated provider. It does not verify real asset downloads or offline transcription.

## Mac live coaching check

Use an invented conversation in a test call. The current hardware evidence covers one MacBook Pro,
Chrome/Meet, and built-in audio through the earlier development check. The new full coaching session
requires an owner test on that setup. Headphones can reduce echo.

1. Run the Composure Mac scheme in Xcode.
2. Open Live Coach.
3. Check that English speech assets and the on-device model are ready.
4. Enter an optional meeting objective.
5. Select the conversation style.
6. Start a test call in Google Meet through Chrome.
7. Select Start coaching in Composure.
8. If macOS requests microphone access, allow access for this test.
9. Select Google Chrome in Apple's sharing picker.
   The selection covers the application, including its other tabs. Composure consumes no screen output.
10. Discuss an invented promotion outcome.
    Allow pauses for speech finalization. Expect occasional short cues in a floating panel.
    The panel provides Stop while Chrome is active. Ordinary discussion can remain silent.
11. Select Stop in the panel.
    Expect the panel, objective, speech context, and current cue to clear. Expect Start to become available again.
12. Confirm that Meet receives your microphone during and after coaching.
13. Start another session.
    Expect an empty objective and no cue carried over from the previous session.
14. Navigate away from the Live Coach view that started the session.
    Expect the session to stop. Switching to Chrome keeps the Mac session active.
15. Change the default audio route during a test session.
    Expect a controlled stop and an explicit new Start before capture resumes.

Test receiving a promotion denial with an objective such as "Understand the evidence missing from my promotion case."
Test explaining a decision with "Agree on concrete development criteria without promising a promotion decision."
Check whether each cue fits the moment. A relevant cue matters more than a high cue count.
Report unsuitable cues, missed useful moments, unexpected interruptions, capture failures, and Stop failures.

The default policy permits at most four cues in ten minutes, with a 20-second cooldown and 90-second
same-type suppression. The profile adjusts frequency. Each cue lasts eight seconds. There is no queue or transcript UI.
The temporary context holds at most 120 seconds, 128 results, and 32 KiB of speech text.
Each model opportunity uses a smaller finalized subset and a fresh tool-free on-device session.
Invalid, late, low-confidence, or refused output remains silent. A failed model check does not stop audio capture.

Speaker identity remains unknown on unverified routes. Interruption, rapid-response, speaking-duration,
and direct-answer cues remain disabled in this first Mac slice. The app does not infer participant emotions or traits.
Stop, navigation, sleep, screen sleep/lock, system session deactivation, route changes, and source failures clear context.
An unconfirmed native Stop keeps Stop available and blocks restart. Quit Composure if retry cannot release capture.

Automated Mac UI tests use synthetic speech and an isolated preference domain. They do not capture a microphone.
The UI runner requires local signing. Ad-hoc signing is sufficient for these development tests:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
    -project src/composure/Composure.xcodeproj -scheme 'Composure Mac' \
    -destination 'platform=macOS,arch=arm64' CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual
```

Run the optional real-model evaluation with invented content only:

```sh
COMPOSURE_EVALUATE_LIVE=1 ./test.sh composure
```

This evaluation requires an available model. It checks two promotion situations, four ordinary remarks,
and three instruction-override fixtures. These checks do not establish broad coaching quality or general injection resistance.
Real audio routes, long physical sessions, offline operation, and post-Stop content searches remain acceptance gates.

## Development Mac audio check

Use the Composure Mac scheme in Debug configuration with the launch argument `--development-audio-check`.
This separate experiment replaces the regular Live Coach screen for that launch.
It checks separate microphone and selected-app audio, two speech analyzers, common-clock timestamps, and bounded processing.
This development screen does not generate coaching feedback. The expected result is changing buffer and recognition-event counts, followed by Stop.
The check does not save audio or recognition text.

1. Open Live Coach and use the inline Speech setup controls until Speech model shows Ready.
   Use Check speech readiness to refresh after a system download completes. Settings provides the same setup controls.
2. Start an empty test call in your meeting app.
3. Confirm that the meeting app receives your microphone before the check starts.
4. Open Live Coach in Composure.
5. Select Start audio check.
6. Allow microphone access if macOS asks.
7. Select the test meeting app in Apple's sharing picker.
   For Google Meet in Chrome, select Google Chrome. The picker selects the application rather than an individual tab.
8. Speak harmless test phrases while the meeting app plays test speech.
   Expect two prepared analyzers, increasing buffer counts for both streams, and recognition events when speech is recognized.
9. Confirm that the meeting app still receives your microphone.
   Buffer counts alone do not verify microphone sharing or audio quality.
10. Select Stop.
    Expect capture and analyzer work to end. The check also requests Stop automatically after 20 seconds.
11. Repeat the test after changing the audio route.
    Expect a route change during a check to stop it and require an explicit restart.

A missing separate microphone stream stops setup. Meeting-audio-only coaching is not offered.
The input queues hold at most eight buffers each. Oversized data, dropped input, or timing discontinuities stop the check.
If Stop cannot confirm success, retry Stop or quit Composure to release capture. The app does not present an idle state in that case.
Closing the check view, system sleep, screen sleep, and user-session deactivation request cleanup.
Release builds exclude this experiment and retain their original capture entitlements.

Report the Mac model, OS version, meeting app, audio route, both buffer and recognition-event counts, microphone sharing, and Stop result.
Built-in audio, wired devices, AirPods, Bluetooth, USB, and display audio need separate observed checks.
Current automated tests use synthetic PCM and passive lifecycle checks. Actual capture compatibility and offline speech remain unverified.

## Native UI tests

Select Composure Mobile and an installed iPhone or iPad simulator in Xcode, then run Product > Test.
The UI test uses an isolated Debug preference domain and synthetic choices.
It checks onboarding, profile restoration, Prepare, Clear, background clearing, and empty preparation after relaunch.
The Prepare journey forces model unavailability and verifies the profile-guidance path.
The root test command runs core tests. Simulator UI tests require this separate Xcode action.
