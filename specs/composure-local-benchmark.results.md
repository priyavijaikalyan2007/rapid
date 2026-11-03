<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: b12bc295-a819-48c1-a972-4603cb84514b
Created: 2026
-->

<!-- AGENT: Measured local-model comparison. No candidate passed the adoption gate. -->

# Local model results on 3 November 2026

No candidate passed the development gate. Keep the production Apple adapter unchanged.
Downloaded models improved this particular action comparison, but each still missed useful actions or produced unsuitable wording.
The separate eight-case verification set remains unused. Cloud integration remains deferred.

## Method and limits

The recorded development host is an Apple M5 Pro Mac with 64 GiB memory, running macOS 26.6.2.
Use these results only for this Mac prototype. They do not establish iPhone, iPad, native Swift, or live-audio performance.
The comparison used 12 frozen cross-topic development cases and five timed turns from the existing synthetic promotion conversation.
Expected actions stayed outside prompts. Fixture text and expected outcomes did not change.

All four candidates used policy version 2 and input format version 2. Background context preceded current speech.
Each request used a fresh session or generation cache, a six-second deadline, temperature zero, and at most 192 output tokens.
MLX used publisher chat templates, disabled optional thinking, and a fixed `{"action":` response prefix.
The strict parser evaluated the complete response. It did not extract JSON from reasoning text or repair replies.
One neutral warmup preceded each measured run. Latency excludes cold load and warmup.

Apple used a new one-pass shared-policy request with guided output. This baseline differs from the production two-pass Apple adapter.
Its model assets are Apple-managed and lack a pinned model identifier here.
MLX used pinned community four-bit conversions and the hash-locked Python environment.
The [artifact manifest](composure-model-artifacts.json) records exact revisions and file hashes.

## Final comparison

An action match requires the expected action or deliberate silence on a negative case.
A Core replay match also requires independent cue validation and actual delivery under the existing timing and repeat rules.
Correct silence counts as a match in both columns. A rejected false cue still fails the case.

| Candidate | Valid structured replies | Action matches | Core replay matches | Latency min / median / max, seconds | MLX peak, GiB |
| --- | --- | --- | --- | --- | --- |
| Apple shared-policy baseline | 17/17 | 7/17 | 7/17 | 0.712 / 0.773 / 0.922 | Not measured |
| Qwen3.5-4B | 17/17 | 15/17 | 14/17 | 0.343 / 0.451 / 0.658 | 3.14 |
| Gemma 4 E4B | 17/17 | 14/17 | 14/17 | 0.439 / 0.583 / 0.645 | 6.05 |
| Qwen3.5-9B | 17/17 | 15/17 | 14/17 | 0.587 / 0.816 / 0.912 | 5.51 |

These small, authored checks are regression gates, not population accuracy estimates or a general model ranking.
All downloaded models selected silence for the six final negative cases, including the resolved agreement and one instruction override.
One override case does not establish general resistance to prompt injection.
MLX peak allocation overlaps process memory and must not be added to it. Apple service memory is not directly comparable.
Audio capture, two speech analyzers, native UI, thermal load, and background transitions were absent from these latency measurements.

## Reviewed failures

Qwen3.5-4B chose REPHRASE for the vague leadership standard in both promotion cases.
The early high-priority REPHRASE also blocked the needed PAUSE six seconds later in Core replay.
The feedback cue was a direct question: "What specific resource gaps are you seeing in the proposal?"
The shared policy requires an instruction to the user and does not permit a direct question.
Core accepts this text, so its replay score overstates wording acceptance.

Qwen3.5-9B chose DONT GUESS for the standalone leadership standard and REPHRASE for the same conversation opening.
Its early REPHRASE also blocked the next PAUSE. The larger model did not improve the final Core score.
"Please explain the specific resource gap you are facing" also assumes that the user owns the concern.
Speaker identity is unknown in this benchmark. That assumption conflicts with the required role-neutral coaching.

Gemma missed the personal attack, unsupported guarantee, and unsupported secret-committee claim.
Five instructions were direct questions, including cases with a correct action label.
For example, "What specific leadership examples are needed?" names a useful topic but violates the required instruction form.
The model also asked about evidence instead of addressing unsupported certainty at conversation second 30.

Apple produced false cues for all six negative cases and missed several required actions.
Some matching labels still carried unsuitable wording or assumptions, such as "I understand your frustration" and instructions to explain the leadership standard.
These issues reinforce the distinction between structured output, action selection, cue delivery, and useful wording.

## Adapter experiments

The first unprimed Gemma run frequently emitted thought-channel text or exhausted its token budget before producing complete JSON.
A subsequent empty-thought-prefix experiment also failed. Both adapters were rejected.
The final fixed JSON prefix produced 17 valid structured replies for every downloaded candidate.
Do not interpret the earlier Gemma parsing failures as its final action-quality score.

Before the final comparison, flat sorted JSON placed current speech before older speech.
Some models coached the older rash reply at second 30. A failing order regression led to the background-first format.
Policy version 2 also clarified intentional silence for AI-output override text.
All final results above use the revised shared contract. Earlier exploratory scores are not interchangeable with these results.

## Evidence and decision

The [checked-in evidence](composure-local-benchmark.evidence.json) contains the final invented replies, runtime records, source report hashes, and Core outcomes.
The final exported fixture SHA-256 is `24579ced8f365337bee3fb19f361d7adb37c1c21c68cb269e03e43507c23f904`.
The policy SHA-256 is `8b33484708177e7c1edd9dd4d48fae76fda67a04690998324fd70026ddbfab25`.
The [application guide](../src/composure/README.md#optional-local-model-benchmark) gives repeatable commands.

No model is selected for adoption. No downloaded model dependency enters the application.
The next quality change must address action selection, role-neutral instructions, and the high-priority cue interaction before native integration.
Qwen3.5-4B offers the smallest measured MLX allocation among these candidates, but that result alone does not justify selection.
Freeze a candidate that passes development and wording review before using the untouched verification set.
Do not request another owner promotion trial at this checkpoint.

## Engineering verification

Boundary tests failed before the parser, artifact checks, response framing, exact version type, and input-order fixes existed.
The final 16 Python benchmark tests passed without loading optional model packages.
The full repository suite passed, including 28 Python tests, 35 Bats checks, native regressions, and 32 website checks.
The Composure build passed active and generic ARM64 Mac builds, mobile simulator compilation, and unsigned mobile device compilation.
Native and shell source-style checks passed. The frozen development and verification source hashes remained unchanged.
These engineering passes do not override the four failed opt-in model quality replays.
No new physical-device, microphone, native downloaded-model, or real-conversation quality check occurred.
