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

Use a full Xcode installation on macOS. The targets require macOS 26 or iOS/iPadOS 26 or later.
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

Compile the Mac target:

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
Unsigned builds do not verify signed sandbox behavior or installation on physical mobile devices.

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
