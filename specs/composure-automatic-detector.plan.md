<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 285753eb-cefb-46ae-945d-fc7071f8bc8f
Created: 2026
-->

<!-- AGENT: Pre-registered bounded automatic detector experiment. No production adoption is implied. -->

# Constrained automatic detector experiment

The owner authorized the next bounded experiment. Automatic coaching during an explicitly started session remains required.
Use the existing pinned Qwen3.5-4B weights. Add no model download, training, cloud call, or production dependency.
Test at most two detector-policy iterations. Preserve original expectations and the unused eight-case verification set.

## Audit and scope

Previous failures include malformed JSON, rewritten quotes, wrong issue labels, unsupported speaker assumptions, and blocked later cues.
Constrained generation can address format and evidence-reference failures. It does not establish sound intervention judgment.
The first prototype covers ambiguity, explicitly missing decisions, and unsupported certainty.
Personal attacks, announced reactions, and concrete disagreements remain outside this prototype's intervention scope.
They still count against the unchanged full development gate when that gate expects advice.
Do not describe a restricted-scope result as passing the full product gate.

Select evidence from bounded sentence-like spans of current speech. Never let the model rewrite evidence or select older speech.
Use fixed reviewed phrases. Keep sparse delivery, confidence validation, expiry, and cooldown unchanged in Core.
Model-selected confidence remains uncalibrated. Do not present it as a measured probability or an adoption guarantee.

## Files and interfaces

- `scripts/composure_detector_policy.py`: span construction, finite observation catalog, strict parsing, and request adaptation.
- `scripts/composure_token_choices.py`: a bounded token trie that permits only catalog completions and then an end token.
- `scripts/composure_benchmark_runtime.py`: optional per-request constrained decoding through the installed MLX logits-processor API.
- `scripts/composure_model_benchmark.py`: opt-in `constrained` mode, policy provenance, and validated observations.
- `test/test_composure_detector.py`: span, parser, trie, injection-boundary, and mode-contract tests before implementation.
- `src/composure/Packages/ComposureCore/Tests/ComposureModelsTests/AutomaticDetectorReplayTests.swift`:
  bounded external invented-fixture replay through actual Core without changing the original replay test.
- `specs/composure-automatic-detector.fixtures.json`: four invented eight-turn conversations frozen before inference.
- `specs/composure-automatic-detector.results.md` and `.evidence.json`: audit, both iteration outcomes when needed, and decision.
- `src/composure/README.md`, `specs/README.md`, `specs/composure.status.md`, `specs/composure-next-decision.md`,
  `PROJECT.md`, `CONVERSATION.md`, `CHANGELOG.md`, and `agentknowledge/{concepts.yaml,entities.yaml,decisions.yaml,history.jsonl}`:
  record commands, acceptance limits, provenance, and the result.

No pattern required. Small pure functions and one request-owned token trie suffice.
Keep policy and evidence selection outside the runtime. Keep CLI routing separate from detection and scoring.

`current_spans(text: str) -> list[str]` returns at most eight exact bounded current-text spans or rejects the input.
`allowed_detections(spans: list[str]) -> list[str]` defines the entire permitted JSON output set.
`parse_detection(text: str, spans: list[str]) -> dict` independently validates issue, span index, and confidence.
`TokenChoices(sequences, end_tokens).allowed(prefix) -> list[int]` is a pure bounded token contract.
Runtime masking uses a fresh trie per request. It must not reuse state or repair completed text.

## Pre-registered checks

The new conversations contain 12 target cue windows and 20 expected-silence turns.
To continue this restricted prototype, require all output contracts to pass, zero displayed false cues on silence turns,
and at least 10 of 12 correct cues delivered within the existing deadline through actual Core.
Require reviewed role-neutral imperative wording in every displayed cue.
A malformed or late reply counts as failure, not correct silence. Withheld useful cues count as misses.
These thresholds are development experiment limits chosen before inference, not release or population-accuracy claims.

Each conversation has routine stretches, current issues, later resolutions, and sufficient space for the unchanged cooldown.
The trial is a development set. A second iteration may use its failures, but must preserve all text, expected actions, and thresholds.
The independent verification set remains unused until the full development and wording gates pass.
Report all 17 original cases alongside the restricted trial. Never remove unsupported cases from the original score.

## Execution and limits

Observe new boundary tests fail before implementation, then pass after implementation.
Verify that an actual MLX request cannot emit a token outside the catalog. Unit tests alone do not establish the integration.
Record the frozen fixture hash, policy hash, raw finite detections, timings, allocations, and actual Core outcomes.
Keep existing input, token, six-second request, five-minute worker, serial-work, and privacy limits.
Run appropriate regression checks, the full repository command, and native compilation when test-source changes require it.
Keep the existing native audio crash separate from detector quality. Do not start physical capture to diagnose this text experiment.
Preserve the owner's Xcode project edit. Commit and push the verified checkpoint with any validation limits stated.

## Second iteration rationale

The first restricted trial passed its pre-registered delivery gate: 32 valid replies, 11 useful cues, and no wrong displayed cues.
However, the detector proposed five unnecessary cues after resolved issues or AI-output instructions.
Core suppressed them. This does not establish that issue detection was correct.
Use the second permitted policy iteration to strengthen current-turn resolution and uncertainty distinctions.
Keep the token catalog, fixture text, expected actions, thresholds, and Core rules unchanged.
The added instructional examples use separate invented subjects. No weights or confidence thresholds are changed.

## Completed result

The second and final restricted trial passed: 32 valid replies, 12 useful cues, and no wrong displayed cues.
Two unnecessary proposals remained and were withheld by cooldown.
Both original-case replays failed. Iteration two passed only 10/17 Core checks, including 10/13 supported-or-silence cases.
The fixed fixture hash and expected outcomes remained unchanged. Verification stayed unused.
The completed budget permits no further prompt iteration. See the [results](composure-automatic-detector.results.md) for the recommendation.
