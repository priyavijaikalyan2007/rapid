<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 88b72b53-d970-4807-bf28-ddcf7bfb5462
Created: 2026
-->

<!-- AGENT: Owner-approved Mac-only V1 scope and 16 GiB reference-machine constraint. -->

# macOS V1 scope

The owner deferred mobile on 3 November 2026. V1 targets macOS 26 or later on Apple silicon.
The performance reference is an M3/M4 MacBook Air with 16 GB unified memory.
Treat the M3 configuration as the slower reference. This is a performance target, not a new hardware block in application code.
The 64 GiB M5 development host does not establish acceptance on that reference machine.

Keep existing mobile source, Xcode targets, and prior evidence as deferred scaffolding.
Remove mobile from active V1 requirements, build routing, and acceptance gates.
Do not edit the owner's existing Xcode project changes or remove targets from that file.
CropPrint keeps its existing mobile scope.

## Files and interfaces

- `test/composure-scripts.bats`: first add failing command-contract tests for Mac-only all mode and rejected mobile mode.
- `src/composure/build.sh`: keep `all`, `test`, `macos`, and `web`. Reject `ios` before tool discovery or side effects.
- `PROJECT_PROFILE.md`, `PROJECT.md`, `ADDITIONAL.md`: record active Mac-only scope and build behavior.
- `README.md`: describe Composure's current Mac-only release scope separately from CropPrint's mobile support.
- `src/composure/product-specification.md`, `implementation-specification.md`, and `implementation-plan.md`: supersede mobile V1 requirements and record the reference machine.
- `src/composure/README.md`: align build commands, manual checks, deferred source status, and hardware limits.
- `specs/composure-model-strategy.plan.md`: keep the next prototype within the 16 GB reference budget.
- `specs/composure.status.md` and `specs/README.md`: record the scope change and measured-versus-planned limits.
- `CONVERSATION.md`, `CHANGELOG.md`, and `agentknowledge/{concepts.yaml,decisions.yaml,history.jsonl}`: preserve the owner decision and verification.

No pattern required. Simple shell functions and case routing suffice.
Keep build selection at the component entry point. The repository dispatcher and CI already delegate to it.
The default build runs Core tests and both active and generic ARM64 Mac destinations.
It must not invoke the Composure Mobile scheme or an iOS destination.

## Model and resource direction

Use Qwen3.5-4B as the next experimental baseline, not an adopted production engine.
Retain Qwen3.5-9B as an optional measured comparison only if the complete workload fits the reference machine.
Do not choose a larger model merely because the development Mac can load it.
Reserve memory and compute for macOS, a browser or meeting app, two speech analyzers, and live capture.
Measure simultaneous memory pressure, swap growth, responsiveness, sustained latency, and thermal behavior on the reference machine.
Do not force system memory limits to imitate a smaller Mac or treat the M5 host as a substitute for hardware testing.

Mac-only scope removes mobile packaging, background, and UI gates from V1.
It does not automatically enlarge transcript retention, context limits, inference deadlines, or concurrency.
Keep the existing bounded-work and privacy rules until a separately measured change justifies an adjustment.
The next quality prototype still needs evidence-based issue detection, application-owned action selection, and separate cue wording.

## Verification

Observe both new shell tests fail against the previous builder before implementation.
Run all shell contract tests, the full repository suite, source-style checks, and `./src/composure/build.sh all`.
Verify that only the pre-existing owner Xcode project edit remains outside the commit.
Commit and push the verified scope change. Do not claim new model quality or reference-machine performance.

## Verified checkpoint

Both new command tests failed against the earlier builder, then passed after the routing change.
The full repository suite passed, including 28 Python tests, 37 Bats checks, native regressions, and 32 website tests.
The revised `all` build passed Core tests and both unsigned ARM64 Mac destinations.
Profile validation, native and shell source-style checks, and patch checks passed.
The owner Xcode project edit remains separate. Reference-machine performance and model quality acceptance remain open.
