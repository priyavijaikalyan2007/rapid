<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 235c58b6-4c51-4648-9ab6-b7ea3455f17a
Created: 2026
-->

<!-- AGENT: Independent small-model comparison. No candidate passed adoption. Automatic coaching remains the product goal. -->

# Ministral and Granite results on 5 November 2026

Neither Ministral 3 3B nor Granite 4.1 3B passed Composure's current quality gate.
Ministral matched Qwen's 14/17 direct Core score but still produced unsuitable wording.
Granite's evidence mode improved its action selection, but malformed replies and a false cue prevented acceptance.
Keep the production application unchanged and the separate verification set unused.

The owner confirmed that automatic, always-on coaching is the core requirement.
User-requested help is an unacceptable substitute. See the [automatic-coaching decision proposal](composure-next-decision.md).

## Method and provenance

Downloaded two public four-bit conversions into ignored local storage with implicit credentials disabled.
Pinned exact revisions and verified weight SHA-256 hashes against Hugging Face metadata.
Verified smaller files against their Git blob identifiers, then recorded SHA-256 hashes for the application-side checks.
The existing benchmark verified every manifest artifact before model loading.
No model dependency, cloud provider, microphone capture, or real meeting text entered the application.

| Candidate | Conversion source | Pinned revision |
| --- | --- | --- |
| Ministral 3 3B Instruct 2512 | [MLX community conversion](https://huggingface.co/mlx-community/Ministral-3-3B-Instruct-2512-4bit) of [Mistral's model](https://huggingface.co/mistralai/Ministral-3-3B-Instruct-2512) | `a962dcb09eee4169c890e544c9eb938f1113fdee` |
| Granite 4.1 3B | [MLX community conversion](https://huggingface.co/mlx-community/granite-4.1-3b-4bit) of [IBM's model](https://huggingface.co/ibm-granite/granite-4.1-3b) | `b1b476b5a17c46b7d6cd663b4a8ed44b66720aef` |

The [artifact manifest](composure-model-artifacts.json) owns complete file lists, sizes, and hashes.
Both publishers and conversions list Apache 2.0. This checkpoint does not redistribute their weights.
The installed MLX-LM 0.32.2 supports both architectures, including text-only loading of Ministral's multimodal conversion.
No new Python dependency was needed.

Used the unchanged 12 development cases and five timed conversation turns.
Both models received the same direct policy and the same evidence policy 2 in separate runs.
No candidate-specific coaching prompt, expected-action change, quote repair, or relaxed parser was added.
Requests remained serial, offline, tool-free, fresh, and bounded by the existing six-second deadline and 192 output tokens.
The runtime reported arm64 and macOS 27.2. Latency excludes loading and a neutral warmup.
These measurements do not establish performance alongside speech and a meeting app on the reference 16 GB Air.

## Tokenizer correction

The exploratory Ministral run warned that its tokenizer used an incorrect regular-expression pattern.
Rejected that adapter state for the final comparison.
Added failing tests before a scoped loader correction that enables `fix_mistral_regex` for the Mistral family.
Confirmed that the corrected tokenizer's pattern exactly matches the pinned `tekken.json` pattern.
The publisher explains this mismatch in its [tokenizer discussion](https://huggingface.co/mistralai/Mistral-Small-3.1-24B-Instruct-2503/discussions/84).
The correction keeps offline loading and disabled remote code. Other model families retain their prior options.

## Final comparison

| Candidate and mode | Valid replies | Action matches | Core replay matches | Latency min / median / max, seconds | MLX peak, GiB |
| --- | --- | --- | --- | --- | --- |
| Ministral direct | 17/17 | 15/17 | 14/17 | 0.279 / 0.422 / 0.497 | 2.42 |
| Ministral evidence | 7/17 | 7/17 | 7/17 | 0.254 / 0.400 / 0.487 | 2.41 |
| Granite direct | 17/17 | 9/17 | 5/17 | 0.322 / 0.445 / 0.558 | 2.61 |
| Granite evidence | 11/17 | 10/17 | 10/17 | 0.386 / 0.475 / 0.578 | 2.60 |

Correct silence counts as a pass. Invalid output is a failure, even when the application would withhold a cue.
An action match also fails Core replay if independent validation or delivery rules reject it.
Core does not catch every wording fault. Human review remains a separate gate.
These authored checks are regression gates, not population accuracy estimates or a general model ranking.
The [invented evidence](composure-additional-models.evidence.json) preserves all four reports, Core outcomes, and bounded diagnostic replies.

## Reviewed failures

Ministral's direct mode selected acceptable actions for all 12 standalone development cases.
In the progressing conversation, it changed vague performance feedback to REPHRASE and chose PAUSE for unsupported speculation.
Several instructions were direct questions. Another attributed feelings to an unknown speaker.
The vague-design instruction exceeded Core's wording bounds, so its correct action label still failed delivery.
Matching a headline therefore overstated acceptable advice.

Ministral's evidence mode failed strict validation in ten cases.
Repeated diagnosis of two rejected cases showed extra escaped quotation marks inside the evidence value.
Those strings were absent from current speech, so the exact-quote check rejected them.
The diagnosed vague-feedback reply also selected `missingDecision`, which would remain wrong after a formatting correction.
Do not strip the quote characters and treat the resulting reply as a measured pass.

Granite's direct mode mostly selected CLARIFY and reported confidence below Core's 0.8 minimum on actionable replies.
It missed unsupported guarantees, a missing owner, an announced rash response, and unsupported hidden intentions.
It also revisited the earlier promotion issue after the final agreement resolved it.
The five Core matches were correct silence cases. Withheld wrong cues still failed their expected cases.

Granite's evidence mode selected correct actions for ten cases, including the conversation's first four turns.
Six replies failed validation. Repeated diagnosis found single-quoted JSON evidence in one reply and nonempty evidence on two `none` replies.
It also produced a valid PAUSE observation for the AI-output override, where the expected action was silence.
These results separate output-contract failures from wrong intervention judgments. Both remain adoption blockers.

## Decision and next gate

Stop generic model comparisons at this checkpoint. No candidate qualifies for native integration or another owner meeting trial.
The tested model-only latencies and allocations are encouraging resource measurements, not evidence of useful automatic coaching.
The data does not establish that automatic coaching is impossible, but it does not justify more unbounded model shopping.

The [next decision proposal](composure-next-decision.md) preserves automatic operation and defines a bounded diagnostic stage.
Audit semantic errors, output-contract failures, speaker evidence, and delivery interactions before choosing a detector or training method.
A hard-constrained observation contract can address some formatting failures. It cannot establish that the chosen intervention is right.
Task-specific training needs varied reviewed data and independent evaluation. The current 17 cases are insufficient.
No manual-help pivot, new detector, training run, or product-scope reduction was implemented.

## Engineering verification

The tokenizer-option tests failed before the loader helper existed. All 54 Python tests and 37 Bats checks then passed.
Native and shell style checks and patch-whitespace checks passed. Core's 129 tests passed during the full run.
The website's 32 checks passed separately after the full run stopped at the native test failure.
All four focused replays evaluated 17 cases and failed quality assertions as recorded.
The full repository command again failed in the unchanged native audio test target with signal 5.
The earlier diagnosed frame was Apple's `AnalyzerInput.data(from:)`. Full native validation remains open.
The owner's Xcode project edit and every frozen evaluation source file remain unchanged.
