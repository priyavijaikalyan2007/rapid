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
The current application provides privacy onboarding, a Coaching Profile, and saved settings through native controls.
Preparation, audio capture, speech recognition, and semantic coaching are not implemented yet.
This build does not request microphone permissions, listen, or run model inference.

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

Run only shared-core tests:

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

The shared package tests lifecycle transitions, typed preferences, recovery, and content-safe diagnostics.
The applications log fixed lifecycle events without profile values or meeting content.
One versioned UserDefaults record stores only coaching choices and app preferences.
Corrupt or unsupported records require explicit recovery. Operating-system backups can include saved preferences.
The Mac target enables App Sandbox without network or capture entitlements.
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

Expect privacy onboarding, editable Settings, and feature-status screens for Prepare and Live Coach.
Expect no microphone or speech permission prompts.
Record the device model, OS version, and launch result in the status record.
No build command uploads or publishes the application.

## What to test now

This stage tests onboarding, saved preferences, navigation, and native layout. Apple Intelligence is not required yet.
Start with one Mac, the iPhone 17 Pro, and the M1 iPad Pro if each runs OS version 26 or later.
Other supported devices can follow. Record older OS versions without changing deployment targets or updating devices automatically.

1. Run ./src/composure/build.sh all from the repository root.
   Expect 44 shared-core tests to pass and all unsigned platform builds to succeed.
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
11. Open Prepare and Live Coach.
    Expect feature-status screens. Live Coach must say that Composure is not listening.
12. Rotate each mobile device.
   Expect readable text and accessible navigation in portrait and landscape.
13. Resize the Mac and iPad windows where supported.
   Expect the native layout to remain usable.
14. Check larger text, VoiceOver, and Mac keyboard navigation.
    Expect labeled controls, readable choices, and accessible Save, Back, and Continue actions.

Report the device model, OS version, launch result, layout issues, and any permission prompt or crash.
Preparation, audio capture, speech recognition, and coaching quality are later test stages.

## Native UI tests

Select Composure Mobile and an installed iPhone or iPad simulator in Xcode, then run Product > Test.
The UI test uses an isolated Debug preference domain and synthetic choices.
It checks onboarding navigation, profile changes, and restoration after relaunch.
The root test command runs core tests. Simulator UI tests require this separate Xcode action.
