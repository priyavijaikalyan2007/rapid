<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: a887a244-11fa-4dd5-9b2e-16b81cdd0744
Created: 2026
-->

<!-- AGENT: Proposed local-model comparison and explicit remote-provider design, not implemented functionality. -->

# Composure model strategy

Status: Initial local benchmark complete. V1 is Mac-only as of 3 November 2026. Cloud integration is deferred.
The current application remains on-device-only.
The [quality investigation](composure-live-quality.plan.md) did not produce an acceptable model revision.
Default regression checks passing do not establish coaching usefulness.
Three models were downloaded into ignored local benchmark storage. No downloaded model entered the production application.
See the [measured comparison](composure-local-benchmark.results.md) and [Mac-only scope](composure-macos-v1.plan.md).

## V1 reference machine and next prototype

Target an M3/M4 MacBook Air with 16 GB unified memory. Use the M3 as the slower performance reference.
The M5 development Mac's 64 GiB memory does not justify a model that requires that capacity.
Use Qwen3.5-4B as the next experimental baseline because the measured prototype has the smallest MLX allocation among these candidates.
That comparison does not select it for production or establish target-machine performance.
Qwen3.5-9B remains an optional comparison if the complete workload fits the reference machine and improves useful coaching.

Reserve resources for macOS, a meeting app or browser, separate audio capture, and two speech analyzers.
Measure memory pressure, swap growth, sustained latency, responsiveness, and thermals under that combined workload.
Do not increase rolling context, model concurrency, or deadlines merely because mobile is deferred.
Keep the next prototype focused on evidence-based issue detection, application-owned action selection, and separate cue wording.
Preserve the untouched verification set until a candidate passes development and wording review.

## Local candidates

Benchmark instruction-tuned, four-bit variants before selecting a replacement. Quantization reduces weight storage but can change output quality.
The recommendation is an evaluation order, not a claim that these models already pass Composure's tests.

| Candidate | Proposed role | Evidence |
| --- | --- | --- |
| Gemma 4 E4B | Measured Mac alternative | Google targets E4B at mobile devices and laptops. The family has Apache 2.0 licensing. [Overview](https://ai.google.dev/gemma/docs/core), [model card](https://ai.google.dev/gemma/docs/core/model_card_4). |
| Qwen3.5-4B | Independent small-model comparison | An instruction-capable open model with Apache 2.0 licensing. [Publisher model card](https://huggingface.co/Qwen/Qwen3.5-4B). |
| Qwen3.5-9B | Mac quality comparison if memory permits | A larger comparison from the same family. Test direct-response mode to control live latency. [Publisher model card](https://huggingface.co/Qwen/Qwen3.5-9B). |

Measure peak memory during speech recognition and inference together. Parameter labels do not establish identical memory needs across model families.
Google lists different memory estimates for generic four-bit and optimized mobile Gemma runtimes. Neither estimate proves fit in Composure.
Consider smaller models only if reference-machine measurements require them. Mobile deployment is outside V1.

Use MLX Swift for the initial Apple Silicon prototype. Its supported architectures include Gemma 4 and Qwen3.5.
Its optional FoundationModels bridge requires the version 27 SDK and runtime. Direct MLX integration needs separate verification against our OS 26 floor.
Pin and verify a release rather than following its changing main branch. [Runtime documentation](https://github.com/ml-explore/mlx-swift-lm).

Start with general instruction models. Do not select a purported coaching specialist without examining its license, training scope, and independent evidence.
Consider fine-tuning only after broader evaluation shows a specific gap and suitable varied data exists.
One promotion example is insufficient training or acceptance evidence.

## Remote providers and subscriptions

Optional cloud processing is a useful product direction. It requires a change to the current privacy specification before implementation.
Use the provider's official inference API and explicit user configuration.

Anthropic directs third-party products, including Agent SDK products, to API-key authentication or a supported cloud provider.
Its documented restrictions prohibit routing third-party app requests through consumer Claude subscription credentials.
The separate allowance for hosting the unmodified Claude Code product does not establish permission to use subscription tokens as Composure's backend.
A configured Claude Code installation therefore does not establish Composure API authorization.
[Anthropic authentication rules](https://code.claude.com/docs/en/legal-and-compliance).

Google AI Pro currently includes monthly Google Cloud credit benefits through the linked Developer Program.
Gemini API access still uses a configured project, key, quota, and billing account.
Eligible credit use can require an active prepaid balance. Subscription status alone does not establish usable or unlimited API access.
[Google AI Pro benefits](https://support.google.com/googleone/answer/14534406?hl=en),
[Gemini API billing](https://ai.google.dev/gemini-api/docs/billing).

Propose two explicit processing choices: on-device, and cloud through a selected API provider.
Keep on-device as the default. Require explicit cloud selection for the session. Never switch to cloud after a local failure without that choice.
Keep capture and speech recognition local. Send only bounded text context and the selected objective and profile fields.
Explain that provider retention and data-use rules differ from Composure's local memory-only behavior.
Store API keys in Keychain. Do not import another application's login tokens or expose provider errors containing submitted text.

Keep tool-free requests, independent output validation, current evidence checks, expiry, Stop cancellation, and cue caps for every provider.
Add a separate request and spending budget. Four displayed cues per ten minutes does not cap repeated model calls or their cost.
Cloud Live Coach must pass latency and usefulness checks. Prepare and invented text replays are the first remote comparison targets.

## Evaluation sequence

1. Build a model-neutral replay harness around the existing Core input and output contracts.
2. Compare Apple, Gemma 4 E4B, and Qwen3.5-4B on the development and progressing-conversation cases.
3. Compare Qwen3.5-9B only within the 16 GB Air reference-machine budget.
4. Keep official Gemini and Claude API comparisons deferred while the owner prioritizes on-device V1.
5. Measure useful actions, grounding, repetition, false cues, missed cues, timeouts, latency, memory, and request cost.
6. Freeze a candidate before using the untouched verification set.
7. Test speech recognition, speakers and headphones, end-to-end latency, and complete conversations after text quality passes.

The current small fixture sets are regression checks. Broader human review must cover roles, topics, accents, cultures, and communication styles.
Model benchmarks do not establish emotion detection or verified speaker attribution. Those capabilities remain outside the accepted live slice.
No production provider, model license bundle, privacy change, or new device promise is accepted by this proposal.
The [initial local benchmark](composure-local-benchmark.results.md) selected no replacement.
Continue within the [Mac-only reference-machine scope](composure-macos-v1.plan.md) before selecting an engine.
