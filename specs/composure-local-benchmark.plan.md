<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 441ff05f-ec98-45cf-a7a5-3952d76f854c
Created: 2026
-->

<!-- AGENT: Authorized Mac-only local-model benchmark. Application integration follows evidence, not model marketing. -->

# Local model benchmark

The owner authorized stronger on-device model evaluation on 1 November 2026. Cloud integration is deferred.
Compare Gemma 4 E4B and Qwen3.5-4B using invented inputs. Keep the application unchanged until a candidate passes.
The current development host reports an Apple M5 Pro, 64 GiB memory, and about 1.5 TiB free storage.
These results will describe this Mac. They will not establish phone or tablet performance.

## Design and interfaces

Use Python MLX LM for the first weight and quality comparison. Keep the environment and weights under ignored local/.
Python results establish prototype behavior. Native Swift integration needs its own latency and device verification after selection.
Use pinned model revisions, safe tensor files, recorded hashes, and disabled remote model code.
Download weights explicitly. Run inference from local paths in offline mode. Read no application preferences, credentials, or meeting data.

Reuse the frozen Swift fixtures through an opt-in exporter. Do not copy their text into a second independently maintained dataset.
Keep expected outcomes outside model prompts. Preserve the untouched verification set until a candidate passes development checks.
Export one fixed policy and bounded JSON inputs so Apple and MLX comparisons can use the same request contract.
Record the existing production adapter baseline separately from any new common-prompt Apple comparison.

Use injected generation functions at the runtime boundary. No new GoF pattern is required for the benchmark driver.
Keep parsing, inference, and scoring separate. Reuse Core cue validation and arbitration through an opt-in replay check.

Proposed Python interfaces:

- `load_fixtures(path) -> dict`: validate invented-data marker, version, bounded case count, unique IDs, and bounded input strings.
- `parse_reply(text) -> dict`: reject duplicate keys, unknown fields, invalid action values, malformed JSON, and non-finite confidence.
- `run_cases(fixtures, generate, clock) -> dict`: serial calls, fixed failure codes, bounded responses, and per-case elapsed time.
- `load_runtime(model_path)`: lazy optional MLX import, local-only model loading, no tools, and a fresh generation cache per request.

Use at most 192 generated tokens initially. Bound input and output bytes. Record six-second live deadline failures separately from action usefulness.
Use cooperative streaming cancellation and a bounded process timeout for a stuck benchmark. Do not change global memory or GPU settings.
Record cold load separately from generation. Record MLX peak allocated memory and dependency versions.
Apple service memory is not directly comparable to the benchmark process's resident memory. Report this measurement limit.

## Files

- `scripts/composure_model_benchmark.py`: benchmark command, validated fixture input, typed output, and sanitized operational failures.
- `scripts/composure_benchmark_runtime.py`: lazy MLX adapter and local-only generation.
- `scripts/composure_benchmark.requirements.txt`: pinned optional benchmark dependencies.
- `test/test_composure_model_benchmark.py`: boundary, malformed output, gold-label isolation, deadline, and failure-redaction tests.
- `src/composure/Packages/ComposureCore/Tests/ComposureModelsTests/LiveQualityConversationScenarios.swift`: shared invented timed turns.
- `src/composure/Packages/ComposureCore/Tests/ComposureModelsTests/LiveConversationQualityTests.swift`: reuse the timed turns without changing expectations.
- `src/composure/Packages/ComposureCore/Tests/ComposureModelsTests/LocalBenchmarkFixtures.swift`: export development inputs and the shared policy.
- `src/composure/Packages/ComposureCore/Tests/ComposureModelsTests/LocalBenchmarkReply.swift`: closed structured reply for common-prompt Apple inference and replay.
- `src/composure/Packages/ComposureCore/Tests/ComposureModelsTests/LocalModelBenchmarkTests.swift`: opt-in export, Apple comparison, and Core replay.
- `specs/composure-model-artifacts.json`: model provenance, pinned revisions, licenses, quantization, and file hashes.
- `specs/composure-local-benchmark.results.md`: measurements, reviewed wording, failures, and selection decision.
- `src/composure/README.md`: repeatable setup and benchmark commands.
- `CONVERSATION.md`, `CHANGELOG.md`, `specs/composure.status.md`, and graph records: verified progress and limits.

Adjust this list before implementation if runtime inspection shows a necessary change.

## Verification

Write failing boundary tests before implementation. Run actual inference only with the exported invented fixtures.
Keep deterministic checks distinct from human review of usefulness, grounding, and voice.
Check false cues, missed cues, repetitions, invalid output, injection attempts, latency, and memory.
Run accepted typed outputs through Core's actual cue arbiter to count delivered cues as well as proposed actions.
Do not hide a failed model check behind default unit-test success.

Freeze a passing development candidate before using the separate verification set. If no candidate passes, record that outcome.
Run the full repository checks and relevant native tests. Commit and push verified checkpoints as work proceeds.
Do not ask the owner for another promotion trial until the model and full-pipeline gates pass.
