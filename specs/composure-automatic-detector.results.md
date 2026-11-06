<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 71a4b8f7-b222-4827-a384-e659b83af03e
Created: 2026
-->

<!-- AGENT: Completed two-iteration constrained detector experiment. Product adoption remains blocked. -->

# Automatic detector results on 6 November 2026

The two-iteration experiment fixed output-contract failures but did not pass the existing coaching-quality gate.
Keep the production application unchanged and stop further prompt iterations at this checkpoint.
The new timed conversation trial passed its restricted delivery gate, but the original cases still exposed wrong judgments and blocked advice.
The independent verification set remains unused.

Automatic, always-on coaching remains the owner's requirement. No manual-help or preparation pivot is proposed as a substitute.
The recommended decision is to pause automatic feature development unless the owner chooses a separate reviewed-data and training effort.
That effort would be a new investment decision with uncertain results, not an extension of this two-iteration prompt budget.

## Audit before implementation

| Failure class | Recorded evidence | Intervention in this experiment |
| --- | --- | --- |
| Output syntax | Granite emitted single-quoted JSON. | Permit only complete catalog outputs during sampling. |
| Evidence rewriting | Ministral added escaped quote characters absent from current speech. | Select an index into exact application-supplied current spans. |
| Wrong issue judgment | Qwen treated vague feedback as a different issue. | Test explicit category boundaries under unchanged expected outcomes. |
| Speaker assumptions and wording | Direct modes asked questions or attributed feelings to an unknown speaker. | Use fixed reviewed phrases and exclude speaker-dependent advice. |
| Delivery interaction | An early wrong action blocked later useful advice through repeat suppression. | Replay through actual Core without changing cooldown, priority, or repeat rules. |

The restricted detector covers unclear criteria, explicitly missing decisions, and unsupported certainty.
Personal attacks, announced reactions, and concrete disagreements remain outside its intervention scope.
Four original cases require those unsupported actions. They remain in the original score and still count as misses.
The restricted detector should remain silent on unsupported situations, but did not always do so.

## Contract and implementation

The application constructs at most eight sentence-like spans copied from current speech.
The model selects a supported issue, a span index, and one of three confidence values.
It cannot supply evidence text or cue wording.
A request-owned token trie masks every token outside the finite catalog before sampling.
An independent strict parser validates the complete reply and resolves the span reference.

The runtime uses the installed [MLX-LM 0.32.2 logits-processor interface](https://github.com/ml-explore/mlx-lm/blob/v0.32.2/mlx_lm/generate.py).
No new dependency or model download was needed. The existing pinned Qwen3.5-4B weights remain separate from the native application.
An actual MLX integration check assigned the highest score to an illegal token and verified that masking rejected it.
The check also covered complete output and end-token lookahead.
All 98 scored replies across the two iterations belonged to their finite catalogs and passed independent parsing.

Confidence remains model-selected and uncalibrated. The values 0.5, 0.8, and 0.9 are permitted outputs, not measured probabilities.
Core's existing 0.8 minimum stayed unchanged. No low-confidence reply was promoted to force delivery.
Sentence splitting establishes text provenance, not semantic correctness or speaker identity.

## Frozen trial and pre-registered limits

Created four invented eight-turn conversations before inference, with 12 target cue windows and 20 expected-silence turns.
The subjects cover a community archive, volunteer planning, a household move, and a workspace access review.
The scripts include routine statements, unresolved issues, later resolutions, an AI-output override, and an untrusted objective.
Previous speech remained a bounded explanatory context. Expected labels and case identifiers never reached the model.

The fixture SHA-256 was frozen before implementation:
`3e6efb82664ee2da5ba777665e2a298004305995d8337ce98c19d38ad5e8a926`.
Neither iteration changed the text, expected outcomes, token catalog, thresholds, or Core rules.
The development gate required 32 valid replies, zero wrong displayed cues, and at least 10 of 12 useful delivered cues.
Wrong proposals withheld by Core were counted separately, not called correct model judgments.

These scripts are authored development data with sampled decision times, not real audio or an independent human-reviewed trial.
Iteration two used iteration-one failures to refine the policy, as the plan permitted.
The new trial therefore does not measure generalization. The independent eight-case verification set remains unused.

## Timed conversation results

| Iteration | Valid replies | Correct proposed actions, including silence | Useful cues delivered | Wrong cues displayed | Unnecessary proposals withheld | Restricted gate |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 32/32 | 27/32 | 11/12 | 0 | 5 | Passed |
| 2 | 32/32 | 30/32 | 12/12 | 0 | 2 | Passed |

Iteration one missed one useful cue because its confidence was 0.5. Core correctly withheld that proposal.
Its five unnecessary proposals concerned resolved issues or the AI-output override. Cooldown or duplicate rules withheld them.
Iteration two strengthened current-turn resolution and acknowledged-uncertainty rules, with separate invented instructional examples.
It reduced unnecessary proposals to two and selected acceptable confidence for every target cue.
The two remaining unnecessary proposals followed an acknowledged uncertainty or a resolved prediction. Cooldown withheld both.

Post-issue silence turns in this trial occur inside the existing cooldown window.
Therefore, zero wrong displayed cues partly reflects protection from Core rather than a correct decision to remain silent.
This result does not establish a low false-cue rate when similar situations occur outside cooldown.
All displayed phrases used reviewed role-neutral imperatives. This establishes wording form, not general coaching usefulness.

## Original regression results

| Iteration | Valid replies | Action matches | Core replay matches | Core matches in supported-or-silence cases |
| --- | --- | --- | --- | --- |
| 1 | 17/17 | 9/17 | 8/17 | 8/13 |
| 2 | 17/17 | 11/17 | 10/17 | 10/13 |

The full original gate still failed after both iterations. Four expected cases lie outside the restricted scope.
Even among the 13 supported-or-silence cases, iteration two failed three checks.
It delivered correct advice in only four of seven supported cue opportunities, while correctly selecting all six required silences.

Two failures involved the same vague-feedback sentence, once alone and once in the progressing conversation.
The model selected unsupported certainty and cited the factual statement that the promotion did not occur.
The selected span came from current speech, but it did not justify that classification.
An announcement of an insulting reply also received unsupported-certainty advice despite lying outside the declared scope.
The earlier wrong DONT GUESS then blocked a needed DONT GUESS at conversation second 30 through unchanged repeat suppression.
Constrained output did not solve this judgment and delivery interaction.

These failures prevent adopting even the restricted detector on the current evidence.
Passing the easier authored conversation trial does not override failures on the original supported cases.
No acceptance label was relaxed and no unsupported case was removed from the full score.

## Runtime measurements

| Suite and iteration | Latency min / median / max, seconds | MLX peak, GiB |
| --- | --- | --- |
| Original cases, 1 | 0.328 / 0.348 / 0.369 | 3.04 |
| Conversations, 1 | 0.342 / 0.374 / 0.506 | 3.05 |
| Original cases, 2 | 0.392 / 0.414 / 0.441 | 3.14 |
| Conversations, 2 | 0.394 / 0.413 / 0.436 | 3.14 |

All requests stayed within the existing six-second deadline and byte and token bounds.
Latency excludes loading and a neutral warmup. Inference was local, serial, tool-free, and offline.
These arm64 macOS 27.2 model-only measurements do not establish performance alongside capture, speech analyzers, and a meeting app on a 16 GB Air.
The [evidence artifact](composure-automatic-detector.evidence.json) preserves policies, hashes, finite detections, observations, and actual Core outcomes.

## Verification and decision

Python contract tests failed before implementation, including strict token-type regressions, and then passed.
All 79 Python tests passed. Repository shell and website checks passed separately.
Four new native gate checks passed. The opt-in restricted trial passed for both iterations.
Original-case Core replays failed quality assertions as recorded. Core's 129 tests passed during the full regression run.
Both unsigned active and generic ARM64 Mac builds passed.
The full repository command still failed because the unchanged native audio test process crashed.
Full native validation, physical audio-route checks, and reference-machine performance remain open.

The two-iteration budget is complete. Do not continue model shopping or prompt tuning under this experiment.
Do not integrate this detector or request another owner meeting trial.
Continuing would require a separate decision to invest in varied reviewed data, task-specific learning, calibration, and independent evaluation.
Those methods may help, but this experiment does not establish that they will work.
If that investment is outside the intended project budget, stopping Composure is the recommended decision.
