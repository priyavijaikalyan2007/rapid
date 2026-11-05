<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 2bd1e374-70a7-43fe-acf4-d1707e1f1e9a
Created: 2026
-->

<!-- AGENT: Publisher-backed model shortlist, separate from Composure benchmark evidence. -->

# Local model shortlist on 5 November 2026

Test the evidence-first Qwen approach before downloading more models. The owner confirmed this sequence.
The target remains a 16 GB M3/M4 MacBook Air alongside a meeting app, capture, and two speech analyzers.
The following choices come from publisher model cards on Hugging Face, checked on 5 November 2026.
Their sizes suggest evaluation candidates. Their published benchmarks do not establish Composure quality or hardware fit.

## Measured candidates

We tested Gemma 4 E4B, Qwen3.5-4B, and Qwen3.5-9B under the same direct-output policy.
Gemma produced 17 valid structured replies and passed 14 of 17 action and Core replay checks.
Review found five direct questions and missed actions. Gemma did not pass adoption.
Qwen3.5-4B passed 15 action checks and 14 Core checks with the smallest measured MLX allocation of these candidates.
See the [recorded comparison](composure-local-benchmark.results.md) for the complete method and limits.

## Additional candidates

| Candidate and publisher source | Published scope | Evaluation judgment |
| --- | --- | --- |
| [Ministral 3 3B Instruct 2512](https://huggingface.co/mistralai/Ministral-3-3B-Instruct-2512) | Small instruction model designed for edge deployment. Publisher lists Apache 2.0. | First additional comparison. Verify a pinned text-capable conversion and runtime before measuring. |
| [Granite 4.1 3B](https://huggingface.co/ibm-granite/granite-4.1-3b) | IBM publishes this 3B conversational model under Apache 2.0. | Second comparison for structured issue detection. No Composure results exist. |
| [Phi-4-mini-instruct](https://huggingface.co/microsoft/Phi-4-mini-instruct) | Microsoft publishes a 3.8B instruction model for constrained and latency-sensitive uses. Publisher lists MIT. | Another independent family. Confirm supported loading without remote model code. |
| [SmolLM3-3B](https://huggingface.co/HuggingFaceTB/SmolLM3-3B) | Hugging Face publishes a 3B model under Apache 2.0. Its card documents disabling extended thinking. | Reserve candidate. The current generic template flag does not establish that its thinking mode is disabled. |
| [LFM3-1.7B](https://huggingface.co/LiquidAI/LFM3-1.7B) | Liquid AI publishes a 1.73B text model for local agents and structured output under its LFM license. | Reserve for tighter resource budgets. Verify offline loading and thinking behavior. The publisher notes that disabling reasoning can be inconsistent. |
| [Llama 3.2 3B Instruct](https://huggingface.co/meta-llama/Llama-3.2-3B-Instruct) | Meta publishes a small instruction model under its Llama 3.2 community license. | Optional Meta-family comparison. Smaller than Muse Glimmer, but no demonstrated advantage for this task. |

This order is engineering judgment, not a measured quality ranking.
No new model above was downloaded, integrated, or benchmarked during this shortlist review.
Any conversion needs provenance, exact revision and hashes, its own chat-template check, and the same quality gates.
Quantized weight size alone does not include model caches, runtime allocations, speech recognition, or macOS.
Liquid AI also retains [LFM2.5-1.2B-Instruct](https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct),
whose card points to LFM3 as the newer version. Neither model has a Composure result.

## GLM and Meta Muse

[GLM-4.7-Flash](https://huggingface.co/zai-org/GLM-4.7-Flash) is a mixture-of-experts model with about 30B total parameters
and about 3B active parameters. Active parameters reduce work per token but do not make it a 3B weight footprint.
I would exclude this model from the initial 16 GB combined workload.
An [older GLM-4-9B-0414 checkpoint](https://huggingface.co/zai-org/GLM-4-9B-0414) exists, but remains an untested, larger comparison.
The GLM family name alone does not establish a resource fit.

Meta's [Muse Glimmer 30B](https://huggingface.co/meta-models/Muse-Glimmer-30B) has downloadable open weights.
Its [publisher GGUF card](https://huggingface.co/meta-models/Muse-Glimmer-30B-GGUF) lists a 16.8 GB four-bit text file
and roughly 17 GB for text weights plus working context. The card also states that reasoning cannot be disabled.
This build is unsuitable for our 16 GB combined workload. The owner acknowledged this limit.
The smaller speculative drafter listed beside Muse is a companion, not evidence of a standalone coaching model.

## Optional Apple wording stage

The owner proposed combining Apple's Foundation Models with another local model.
A staged pipeline can use a downloaded model for issue detection, application rules for actions, and Apple for wording.
This differs from internal mixture-of-experts routing inside one model.
There is no measured evidence that adding Apple improves Composure's cues.

Start with reviewed fixed phrases to isolate detection errors and remove generated questions and speaker-role assumptions.
Only after detection passes, compare optional Apple wording against the same phrases and accepted observations.
Keep the action fixed. Bound wording requests, validate output independently, and reject text that changes the advice or assumes speaker roles.
Account for both stages within the existing total deadline and shared work slot.
If wording fails or is late, use the reviewed phrase only while its validated cue remains current and eligible.
Measure both models alongside the meeting and speech workload before native adoption.
