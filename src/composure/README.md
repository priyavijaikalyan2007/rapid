<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: f6dced28-f65c-44dd-b0da-e73996a9e0a9
Created: 2026
-->

<!-- AGENT: Describes the executable Composure foundation, local commands, and remaining feature gates. -->

# Composure

Composure V1 is a private conversation coach in development for Apple silicon Macs.
The performance reference is an M3/M4 MacBook Air with 16 GB unified memory, using the M3 as the slower baseline.
Existing mobile source and Xcode targets remain deferred scaffolding outside V1.
The application provides privacy onboarding, saved profile settings, and private conversation preparation through native controls.
Settings also checks device prerequisites and offers explicit speech-asset setup.
Prepare uses an on-device model for situation-specific coaching, with labeled profile-based guidance when generation is unavailable.
Preparation input and results remain in memory. Mac Live Coach now supports explicitly started remote sessions and occasional on-device cues.
Mac Debug and Release builds capture separate microphone and selected-application audio after Start.
A separate Debug audio check remains available for development.
Opening the app, checking readiness, and setting up speech do not request microphone access or start listening.

Read the [normative specification](implementation-specification.md) for requirements.
Read the [implementation plan](implementation-plan.md) for the full release sequence.
Read the [foundation review](../../specs/composure-foundation.plan.md) and
[status record](../../specs/composure.status.md) for current work and verification limits.

## Local development

Use a full Xcode installation on an Apple silicon Mac.
V1 requires macOS 26 or later. Composure's Mac application supports arm64 only.
The shared package uses Swift 6 and contains no external dependencies.
The build script selects /Applications/Xcode.app/Contents/Developer when DEVELOPER_DIR is unset.
All generated outputs remain under this component's ignored build directory.

Run Core tests and compile both Mac destinations from the repository root:

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

Mobile builds are deferred. The `ios` mode stops before tool discovery and explains the V1 scope.
The repository dispatcher and CI use this same Mac-only component builder. CropPrint keeps its mobile builds.

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
Unsigned builds do not verify signed sandbox behavior or release readiness.

Debug builds use the active architecture, matching Swift package behavior for Xcode's My Mac destination.
Generic command-line builds set matching app and package architectures explicitly.
If an open Xcode project retains the old architecture settings, reopen the project before building again.

## Device launch check

1. Open Composure.xcodeproj in Xcode.
2. Select the Composure Mac scheme.
3. Select your Mac.
4. Select your development team if Xcode requires signing.
5. Run the application.
6. Complete the four setup steps.
7. Check each navigation destination.

Expect privacy onboarding, editable Settings, Prepare, and Mac Live Coach controls.
Expect no microphone or speech permission prompts.
Record the device model, OS version, and launch result in the status record.
No build command uploads or publishes the application.

## What to test now

Use the [Mac live coaching procedure](#mac-live-coaching-check) for the new milestone.
The following foundation checks cover onboarding, saved preferences, preparation, and native layout.
Prepare works without Apple Intelligence through profile-based guidance.
Use a Mac running macOS 26 or later. Record its model, memory, and OS version.
Functional checks on the development Mac do not establish performance on the 16 GB Air reference machine.

1. Run ./src/composure/build.sh all from the repository root.
   Expect Core and model-adapter tests to pass, plus both unsigned Mac destinations.
   Opt-in live-model evaluations are skipped by default.
2. Run the Composure Mac scheme on one Mac through Xcode.
   Expect onboarding on the first launch, then Home, Prepare, Live Coach, and Settings in the sidebar.
3. Use Back and Continue during setup.
   Expect each disclosure to remain readable and profile choices to remain when you return to them.
4. Change profile choices before you select Finish setup.
   Expect setup to complete without an audio permission prompt.
5. Change a profile choice in Settings.
   Expect an unsaved-change status until you select Save or Discard changes.
6. Select Save.
   Expect the saved status and your selected values after you quit and relaunch the app.
7. Select Reset coaching profile and cancel the confirmation.
   Expect no change to the profile.
8. Confirm Reset coaching profile.
   Expect default profile values, preserved session defaults, and no repeat of onboarding.
9. Open Live Coach.
   Expect the Mac session to show Not listening before Start.
10. Resize the Mac window.
    Expect the native layout to remain usable.
11. Check larger text, VoiceOver, and Mac keyboard navigation.
    Expect labeled controls, readable choices, and accessible Save, Back, and Continue actions.

Report the device model, OS version, launch result, layout issues, and any permission prompt or crash.
Mac audio capture, speech recognition, and cue quality use the separate live procedure below.

## Prepare checks

1. Open Prepare on the Mac.
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
10. Quit and relaunch the application.
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

The objective and conversation style are editable before Start and after confirmed Stop.
Both controls remain locked while the session is active, stopping, or awaiting Stop confirmation.
Pauses in speech do not end a session. Select Stop before changing the objective or style.

Test receiving a promotion denial with an objective such as "Understand the evidence missing from my promotion case."
Test explaining a decision with "Agree on concrete development criteria without promising a promotion decision."
Check whether each cue fits the moment. A relevant cue matters more than a high cue count.
Report unsuitable cues, missed useful moments, unexpected interruptions, capture failures, and Stop failures.

The default policy permits at most four cues in ten minutes, with a 20-second normal cooldown.
Similar repeated advice stays suppressed for 90 seconds. Distinct advice can reuse a headline after the cooldown.
PAUSE and REPHRASE can replace a normal cue. They have an eight-second cooldown and remain subject to all frequency caps.
The entire PAUSE or REPHRASE action stays repeat-suppressed for 90 seconds to limit repeated urgent suggestions.
Each cue lasts eight seconds. There is no queue or transcript UI.
The temporary context holds at most 120 seconds, 128 results, and 32 KiB of speech text.
Each model opportunity uses a smaller finalized subset and a fresh tool-free on-device session.
Invalid, late, low-confidence, or refused output remains silent. A failed model check does not stop audio capture.

Debug builds show content-free coaching diagnostics during listening. Counts distinguish finalized speech,
model checks, no selected action, failures, withheld cues, and displayed cues. Stop clears these counts.
The current model's usefulness checkpoint remains open. Explicit harsh-wording and rash-reply routing still need
a model implementation that passes broader checks. The app does not detect emotions.

Run the broader invented live cases separately from Prepare evaluation:

```sh
COMPOSURE_EVALUATE_LIVE_QUALITY=development ./test.sh composure
COMPOSURE_EVALUATE_LIVE_QUALITY=conversation ./test.sh composure
COMPOSURE_EVALUATE_LIVE_QUALITY=verification ./test.sh composure
```

The development set contains 12 cases across work and everyday topics. The separate eight-case set has no promotion case.
Freeze a candidate before running verification. Do not tune against verification results without replacing that set.
These authored regression cases do not establish broad accuracy, real speech quality, or fairness across people and accents.

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

## Optional local model benchmark

This developer tool compares downloaded models using invented text. It does not change the application's model or start audio capture.
See the [results and limits](../../specs/composure-local-benchmark.results.md) before interpreting a score.
Never pass real conversation text to this harness. Its reports retain the supplied invented replies on disk.
Model weights, caches, dependencies, and local reports belong under ignored `local/composure-benchmark/`.

1. Create the optional Python environment on an Apple silicon Mac with Python 3.14.

   ```sh
   python3.14 -m venv local/composure-benchmark/venv
   local/composure-benchmark/venv/bin/python -m pip install --require-hashes \
       -r scripts/composure_benchmark.requirements.txt
   ```

   The lock records the tested Mac ARM64 wheel set. These packages are separate from native app dependencies.

2. Download one pinned public conversion from the checked-in artifact manifest.

   ```sh
   local/composure-benchmark/venv/bin/python - <<'PY'
   import json
   import os
   from pathlib import Path

   os.environ["HF_HOME"] = str(Path("local/composure-benchmark/hf-home").resolve())
   os.environ["HF_HUB_DISABLE_IMPLICIT_TOKEN"] = "1"
   from huggingface_hub import snapshot_download

   model_id = "qwen3.5-4b"
   manifest = json.loads(Path("specs/composure-model-artifacts.json").read_text())
   model = next(item for item in manifest["models"] if item["id"] == model_id)
   snapshot_download(repo_id=model["repository"], revision=model["revision"],
                     allow_patterns=[item["path"] for item in model["files"]], token=False,
                     local_dir=Path("local/composure-benchmark/models") / model_id)
   PY
   ```

   The manifest lists conversion and upstream provenance. Weight licenses remain the publishers' licenses.
   The Qwen 4B conversion omits a separate license declaration. Redistribution needs its own license review.

3. Export the frozen development inputs directly to a file.

   ```sh
   COMPOSURE_BENCHMARK_MODE=export-development \
   COMPOSURE_BENCHMARK_EXPORT_PATH="$PWD/local/composure-benchmark/development.json" \
       ./test.sh composure
   ```

   The export contains the shared policy, bounded model inputs, and separate expected outcomes.
   The inference driver sends only the policy and input fields to the model.
   Direct file export avoids interleaved Swift Testing output corrupting JSON.

4. Run local inference with a new report path.

   ```sh
   local/composure-benchmark/venv/bin/python scripts/composure_model_benchmark.py \
       --fixtures local/composure-benchmark/development.json \
       --model-dir local/composure-benchmark/models/qwen3.5-4b \
       --model-id qwen3.5-4b \
       --output local/composure-benchmark/qwen-report.json
   ```

   The worker verifies every pinned artifact before loading weights. Inference runs offline without model tools or remote model code.
   Requests are serial and bounded. A six-second deadline failure differs from intentional silence.
   The process watchdog stops a worker after five minutes. Existing reports are not overwritten.

5. Replay the replies through Composure's actual cue rules.

   ```sh
   COMPOSURE_BENCHMARK_REPLAY="$PWD/local/composure-benchmark/qwen-report.json" ./test.sh composure
   ```

   Every expected action must also survive independent validation and sparse cue arbitration.
   A quality failure causes this opt-in test to fail. Read each instruction for grounding and useful wording too.
   A default test pass does not mean that the model passed this quality check.

6. Run the optional Apple comparison under the same exported policy version.

   ```sh
   COMPOSURE_BENCHMARK_MODE=apple-development \
   COMPOSURE_BENCHMARK_OUTPUT_PATH="$PWD/local/composure-benchmark/apple-report.json" ./test.sh composure
   ```

   Apple Intelligence must be available. This uses a new one-pass benchmark request, separate from the production Apple adapter.
   Use the same replay command for its report. Keep the separate verification set unused until a candidate passes development review.

### Optional evidence-first benchmark

The developer benchmark also supports `--mode evidence`. It requests an issue and an exact quote from current speech.
Application-owned rules select an action and fixed wording. Direct output remains the default mode.
Both evidence policies failed the development gate. Read the [measured results](../../specs/composure-evidence-prototype.results.md).
The [model shortlist](../../specs/composure-model-shortlist.md) records additional Hugging Face choices and hardware limits.

Use the same invented fixture export and pinned environment described above:

```sh
local/composure-benchmark/venv/bin/python scripts/composure_model_benchmark.py \
    --fixtures local/composure-benchmark/development.json \
    --model-dir local/composure-benchmark/models/qwen3.5-4b \
    --model-id qwen3.5-4b --mode evidence \
    --output local/composure-benchmark/qwen-evidence-new.json
```

Select an unused report path. Replay it through Core using `COMPOSURE_BENCHMARK_REPLAY` as described above.
An exact quote establishes text provenance, not correct interpretation. Keep the separate verification set unused until development passes.
The prototype does not change the application's model or start capture.

### Optional constrained detector experiment

The benchmark supports `--mode constrained` for three automatic cue types and fixed reviewed wording.
It selects exact current-speech span references through a finite token catalog. No native model integration is included.
The two-iteration experiment failed the original quality gate. Read the [results](../../specs/composure-automatic-detector.results.md) first.

1. Run the frozen invented conversation trial using verified local weights.

   ```sh
   local/composure-benchmark/venv/bin/python scripts/composure_model_benchmark.py \
       --fixtures specs/composure-automatic-detector.fixtures.json \
       --model-dir local/composure-benchmark/models/qwen3.5-4b \
       --model-id qwen3.5-4b --mode constrained \
       --output local/composure-benchmark/qwen-detector-new.json
   ```

2. Replay the report through Core's actual delivery rules.

   ```sh
   COMPOSURE_DETECTOR_FIXTURES="$PWD/specs/composure-automatic-detector.fixtures.json" \
   COMPOSURE_DETECTOR_REPORT="$PWD/local/composure-benchmark/qwen-detector-new.json" \
   COMPOSURE_DETECTOR_REPLAY_OUTPUT="$PWD/local/composure-benchmark/qwen-detector-new-core.json" \
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test \
       --package-path src/composure/Packages/ComposureCore \
       --scratch-path src/composure/build/Core --enable-code-coverage \
       --filter AutomaticDetectorReplayTests
   ```

Select unused output paths. The replay refuses to overwrite its outcome file.
Passing this restricted development trial does not pass the original product gate or establish real-call usefulness.
Reports retain invented content. Never pass real meeting text to these developer tools.

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

Select Composure Mac and My Mac in Xcode, then run Product > Test.
The UI test uses an isolated Debug preference domain and synthetic choices.
The Mac journeys check onboarding, profile state, and synthetic live controls without real audio capture.
The root test command runs package tests. Native UI journeys require this separate Xcode action.

## Reference-machine performance gate

Evaluate the full pipeline on an M3/M4 MacBook Air with 16 GB unified memory before claiming target performance.
Run capture, both speech analyzers, inference, and a representative meeting application together for a sustained session.
Include Chrome with Google Meet in the measured workload.
Record memory pressure, swap growth, responsiveness, cue latency, and thermal behavior.
Keep existing context bounds, inference deadlines, and concurrency limits until measurements justify a change.
The 64 GiB M5 benchmark host and model-only allocation figures do not satisfy this gate.
See the [Mac-only scope plan](../../specs/composure-macos-v1.plan.md) for the active scope and resource direction.
