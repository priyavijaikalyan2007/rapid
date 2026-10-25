<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: d513678d-6a2e-46b9-afb1-d4118df0f835
Created: 2026
-->

<!-- AGENT: Separates Composure planning documents from implemented application work. -->

# Composure status

Updated on 25 October 2026.

Composure has an executable native foundation under src/composure.
The Mac and universal iPhone/iPad targets use a local Swift package with strict Swift 6 concurrency.
Composure supports Apple silicon Macs only. Its Debug and Release Mac applications use arm64.
The profile now enables Composure as a native component, alongside the existing documentation scope.
The application provides four privacy onboarding steps, editable Coaching Profile settings, and native navigation.
The shared core includes typed preferences and a bounded UserDefaults adapter.
Settings provides explicit Save, Discard, and confirmed profile reset actions.
Prepare, capture, speech, and semantic coaching remain unimplemented.

The [normative specification](../src/composure/implementation-specification.md) is the implementation contract.
The [product specification](../src/composure/product-specification.md) explains the product and design.
The [implementation plan](../src/composure/implementation-plan.md) defines milestones and acceptance gates.

Preserve the specification's on-device processing, explicit listening controls, and transient session-data requirements.

## Source audit on 24 October 2026

The source audit reviewed all three planning documents on 24 October 2026.
The changes add notices, clarify wording, reflow prose, and format illustrative Swift examples.
At that source-audit checkpoint, no Composure app was implemented or tested.

## Specification review and owner decisions

The [foundation plan and review](composure-foundation.plan.md) records findings and the file-level implementation plan.
The owner confirmed Mac, iPhone, and iPad support on operating system version 26 or later.
Remote setup must stop if separate microphone capture is unavailable.
The owner accepted bounded model inputs, prompt-injection tests, precise audio timing, explicit background behavior,
and early dual-stream feasibility testing. The normative specification and implementation plan now include these requirements.

The owner listed an M5 MacBook Pro, M4 Mac mini, M4 Mac Studio, M1 iPad Pro 12.9-inch,
iPad Air 3, iPhone 12 mini, iPhone 14 Pro, and iPhone 17 Pro for testing.
Their OS versions and Apple Intelligence settings remain unverified, except for the development Mac's macOS 26.6.2.
CoreDevice reports a paired, available iPhone 17 Pro and an unavailable physical iPad.
The inventory does not prove an application launch or feature compatibility on either device.

## Foundation verification

- The new shell routing tests failed before the command implementations existed.
- The root routing and source-style tests failed before Composure was included.
- SwiftPM initially failed at the sandbox boundary. That failure did not count as a failing behavior test.
- An authorized run against an empty core module then failed because the tested domain types were absent.
- The implemented core passed 15 Swift Testing tests, including a four-case cancellation test.
- Core production line coverage measured 43 of 52 lines, or 82.69 percent.
- The full Composure build passed for macOS, iOS simulator, and physical iOS device compilation.
- Generated Mac and mobile metadata declare minimum OS version 26. The mobile device family is [1, 2].
- The Mac application launched, displayed its native sidebar, and changed to the Live Coach status screen.
- Visual inspection confirmed readable native layout and the explicit statement that Composure is not listening.
- The complete root test command passed 12 Python checks, 34 Bats checks, CropPrint tests,
  15 Composure tests, 32 website tests, and six-page website validation.
- The source-style checker passed for both native applications and the component shell scripts.

The development toolchain is Xcode 27.1. Deployment targets remain version 26.
The current foundation contains no capture, speech, model, database, or network implementation.
The logging interface accepts only approved event identifiers and bounded numeric counts.
The initial foundation emitted only the fixed launch event to native unified logging.
Preference integration adds fixed lifecycle events without profile values or meeting content.

## Remaining gates and next slice

Phase 0 is not complete. Physical iPhone and iPad launch checks, signed sandbox checks,
and the later pipeline domain contracts remain open.
Unsigned compilation does not verify those checks. UI automation also showed severe tool delays during this session.
No archive, upload, App Store submission, or website deployment occurred.
Verified development checkpoints now reach origin/main under the owner's ongoing authorization.

Use the [device launch procedure](../src/composure/README.md#device-launch-check) to verify the mobile shells.
Record device models, OS versions, and launch results before marking the Phase 0 device gate complete.
Privacy onboarding, the Coaching Profile, and non-sensitive preference persistence now have native implementations.
Prepare is the next feature slice, with deterministic fallback and explicit model readiness.

## GitHub checkpoint on 24 October 2026

The owner authorized ongoing commits and pushes. Foundation commit 1974880 reached origin/main.
The first remote Build run failed because the runner used SwiftFormat 0.63.0.
That version rejected the checked-in wrap-closure-bodies option before application tests ran.
The workflow now downloads the official 0.64.1 release and verifies the release asset's SHA-256 digest.
The workflow also selects macOS 26 because the Composure package tests require a version 26 host.
These workflow changes do not alter application behavior. Their remote result remains separate from local build evidence.

## Active Mac build correction on 24 October 2026

The owner reported that ApplicationDiagnostics.swift could not import ComposureCore.
The full compiler log showed an x86_64 app compile trying to import an arm64-only package module.
The earlier generic builds and hosted Build run passed because they did not exercise the active Mac destination.
An active arm64 destination reproduced the exact failure locally with exit code 65.

The owner confirmed Apple silicon-only Mac support during this investigation.
Both Mac configurations now specify ARCHS=arm64.
Debug uses ONLY_ACTIVE_ARCH=YES so app and package selection match Xcode's My Mac destination.
The component builder checks active and generic arm64 Mac destinations and applies matching generic build settings.
The product and implementation specifications now record the hardware scope.

Verification passed:

- The new shell coverage test failed before the active Mac check was added, then passed after implementation.
- The previously failing destination passed using the same build directory, without deleting its contents.
- A fresh active Debug build passed without architecture overrides.
- A fresh generic Release build passed without architecture overrides.
- Debug and Release executables each contain only arm64 code, as reported by lipo.
- The component's full build passed, including 15 core tests and both mobile variants.
- The full repository test command passed 12 Python checks, 35 Bats checks, CropPrint tests,
  15 Composure tests, 32 website tests, and six-page website validation.
- Source-style checks and project property-list validation passed.

Interactive Xcode launch and signed mobile checks remain separate gates.
Reopen an existing Xcode project if it retains the previous architecture settings, then run Composure Mac on My Mac.

## Profile core checkpoint

The owner confirmed that the corrected Mac shell works and looks good.
The [profile plan](composure-profile.plan.md) defines the next native feature slice.
The core now provides bounded behavioral preferences, typed persistence, and a main-actor draft/save coordinator.
Only a versioned AppPreferences record can enter the adapter. The record has no conversation text fields.
Stored input is bounded to 16 KiB. Corrupt and unsupported records remain unchanged until explicit reset.
The privacy manifest declares app-only UserDefaults access through CA92.1.

Tests failed before the new contracts existed, then passed after implementation.
The package passed 42 tests across five suites. Production line coverage measured 223 of 248 lines, or 89.92 percent.
The profile has full line coverage. Storage and coordination each exceed 96 percent line coverage.
All component builds passed for active and generic arm64 Mac destinations, the mobile simulator, and physical mobile compilation.
The native apps still show the shell at this checkpoint. Their next change connects onboarding and settings to this core.
Physical iPhone/iPad launch checks remain open.

## Native profile integration on 25 October 2026

Connected four onboarding steps and native Settings to the typed preference core.
Back navigation retains the profile draft. Finish saves the profile and completion flag together.
Settings exposes all eight focus weights, executive restraint, cue preferences, and the default conversation style.
English remains the only coaching language. Audio and model readiness are explicitly unchecked.
Save and Discard are explicit. Native reset alerts offer Cancel and preserve unrelated app preferences.
Unsaved session-default changes remain pending when the profile is reset.
The Mac main window and Settings window share one preference coordinator.

Verification passed:

- The native onboarding test failed against the shell before UI implementation.
- A reset-scope regression failed before the coordinator correction, then passed.
- The core passed 44 tests across five suites, with 231 of 257 production lines covered, or 89.88 percent.
- Profile line coverage is 100 percent. Coordination and storage each exceed 95 percent.
- The mobile UI journey passed on iPhone 17 Pro and iPad Pro 13-inch M5 simulators running OS version 26.5.
- The journey checked Back, Finish, restoration, Save, Discard, reset cancellation, and reset persistence after relaunch.
- The reset test exposed a missing explicit Cancel action. Native alerts now provide that action on both devices.
- Exported test screenshots showed readable native Settings on both simulator sizes.
- Active and generic arm64 Mac builds, mobile simulator builds, and physical mobile compilation passed.
- The complete repository test command passed, including repository, CropPrint, Composure, and website validation.
- Source-style checks, project and privacy property-list checks, and the configured profile check passed.

The initial switch test tapped an accessibility wrapper rather than its nested native control.
The corrected test verifies the selected value before Finish and after relaunch.
Debug UI tests use a separate preference domain and cannot reset ordinary application preferences.

Physical mobile installation, Mac profile interaction, VoiceOver, larger text, rotation, and signed sandbox checks remain open.
The [current test guide](../src/composure/README.md#what-to-test-now) covers those checks.
The native profile slice is implemented. The next feature slice is Prepare and on-device model readiness.
