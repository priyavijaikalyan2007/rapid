<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: f6dced28-f65c-44dd-b0da-e73996a9e0a9
Created: 2026
-->

<!-- AGENT: Describes the executable Composure foundation, local commands, and remaining feature gates. -->

# Composure

Composure is a planned private conversation coach for Mac, iPhone, and iPad.
The current application contains native navigation and explicit feature placeholders.
Preparation, profiles, audio capture, speech recognition, and semantic coaching are not implemented yet.
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

Run all foundation checks from the repository root:

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

The shared package tests lifecycle transitions and a logging facade that accepts fixed event identifiers and bounded counts.
The applications use system unified logging for the fixed application-launch event only.
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
6. Check each navigation destination.

Expect feature-status screens and no microphone or speech permission prompts.
Record the device model, OS version, and launch result in the status record.
No build command uploads or publishes the application.

## What to test now

This stage tests installation, launch, navigation, and native layout. Apple Intelligence is not required for this shell.
Start with one Mac, the iPhone 17 Pro, and the M1 iPad Pro if each runs OS version 26 or later.
Other supported devices can follow. Record older OS versions without changing deployment targets or updating devices automatically.

1. Run ./src/composure/build.sh all from the repository root.
   Expect 15 shared-core tests to pass and all three unsigned platform builds to succeed.
2. Run the Composure Mac scheme on one Mac through Xcode.
   Expect Home, Prepare, Live Coach, and Settings in the sidebar.
3. Run the Composure Mobile scheme on a physical iPhone through Xcode.
   Expect Prepare, Live Coach, and Settings tabs.
4. Run the Composure Mobile scheme on a physical iPad through Xcode.
   Expect the same destinations in a layout that fits the available window.
5. Open each destination on every test device.
   Expect feature-status screens. Live Coach must say that Composure is not listening.
6. Rotate each mobile device.
   Expect readable text and accessible navigation in portrait and landscape.
7. Resize the Mac and iPad windows where supported.
   Expect the native layout to remain usable.
8. Relaunch each application.
   Expect no crash and no microphone or speech permission prompt.

Report the device model, OS version, launch result, layout issues, and any permission prompt or crash.
Preparation, profile persistence, audio capture, speech recognition, and coaching quality are later test stages.
