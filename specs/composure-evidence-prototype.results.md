<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: fc9406e5-4e56-4b28-aa3b-1264103dcafe
Created: 2026
-->

<!-- AGENT: Measured evidence-first experiments. Neither revision passed the development gate. -->

# Evidence-first results on 5 November 2026

The evidence-first prototype did not improve Qwen3.5-4B's Core replay score.
Keep the application's existing model unchanged. Do not add an Apple wording stage yet.
Fixed phrases removed generated questions and role assumptions from this experiment, but issue detection still failed.
The separate verification set remains unused.

## Method

Used the same 12 development cases and five timed conversation turns as the earlier comparison.
Neither the speech text nor its expected actions changed. Expected labels stayed outside model requests.
Used the same pinned, hash-verified four-bit Qwen weights and isolated offline MLX environment.
Requests stayed serial, fresh, tool-free, and subject to the existing input, output, and six-second limits.
No audio capture or real conversation content entered this experiment.

The runtime reported arm64 and macOS 27.2. The earlier comparison reported macOS 26.6.2.
Therefore, reran the direct-output baseline during this session rather than comparing latency across operating-system versions.
Latency excludes model loading and one neutral warmup. These measurements do not establish 16 GB Air performance.

Evidence mode requests one issue classification, confidence, and an exact quote from current speech.
The parser rejects malformed observations and quotes absent from current speech.
Application code maps valid classifications to the existing cue actions and fixed, reviewed phrases.
The actual Core validator and arbiter still determine whether a cue can display.
An exact quote proves where the text came from, not whether the classification is correct.

## Comparison

| Qwen3.5-4B mode | Valid replies | Action matches | Core replay matches | Latency min / median / max, seconds | MLX peak, GiB |
| --- | --- | --- | --- | --- | --- |
| Fresh direct baseline | 17/17 | 15/17 | 14/17 | 0.347 / 0.460 / 0.644 | 3.14 |
| Evidence policy 1 | 17/17 | 13/17 | 12/17 | 0.336 / 0.518 / 0.623 | 3.11 |
| Evidence policy 2 | 16/17 | 14/17 | 14/17 | 0.370 / 0.542 / 0.643 | 3.14 |

These small authored checks are regression gates, not estimates of general coaching accuracy.
The [invented evidence](composure-evidence-prototype.evidence.json) preserves all three reports, policies, hashes, and Core outcomes.

Policy 1 still classified vague performance feedback as a personal attack in two cases.
Its early REPHRASE also blocked the needed PAUSE six seconds later under the unchanged Core rules.
It generated false cues for an AI-output override and the final resolved agreement.

Policy 2 put the evidence field first and stated ordered silence gates before issue classification.
It corrected silence on the resolved agreement and allowed the later PAUSE to display.
However, it classified vague feedback as unsupported certainty and returned invalid output for the same conversation opening.
It also proposed PAUSE for the AI-output override instead of silence.
The strict parser rejected the invalid reply. No quote repair, action substitution, or deadline extension occurred.

The override failure was a false coaching cue. Fixed phrases did not reproduce the requested marker or expose the policy.
This one case does not establish general prompt-injection resistance.
Generic fixed phrases can also suppress distinct later issues through duplicate-cue rules.
Broader wording and multi-turn checks remain necessary before integration.

## Decision

Retain evidence mode as an optional development experiment. Direct mode remains the benchmark default.
Neither evidence revision qualifies for native integration or a new owner meeting trial.
Adding another model for wording cannot establish correct detection of the current issue.

The next bounded comparison should evaluate an independent small model family before further prompt tuning.
[Ministral 3 3B and Granite 4.1 3B](composure-model-shortlist.md) are the first researched candidates.
They still require pinned artifacts, supported offline loading, and the same development and wording gates.
No new candidate was downloaded during this work.

## Engineering verification and limits

The original 16 benchmark boundary tests passed before changes.
New tests failed because evidence mode and configurable response framing did not exist, then passed after implementation.
All 51 Python tests and 37 Bats checks passed. Native and shell style checks passed.
The website's 32 checks passed separately. Core's 129 tests passed.
All focused replays evaluated 17 cases and failed their quality assertions as shown above.

The full repository command failed because an unchanged native audio test process crashed.
The crash report identifies `CaptureCheckAudioConverterTests.convertedPacketsKeepAContinuousSampleTimeline()`
and Apple's `AnalyzerInput.data(from:)`, with SIGTRAP.
The full run also reported an installed CoreSimulator version older than the selected Xcode version.
Neither condition is a model-quality result. Full native validation remains open.
No Swift source, native model dependency, cue rule, audio path, or owner Xcode project edit changed in this prototype.
