<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: a845bc45-1a14-4f8e-9adb-dbe60e66bcdf
Created: 2026
-->

<!-- AGENT: Proposed decision for the required automatic always-on coach. Manual-help alternatives are rejected. -->

# Composure decision checkpoint

The current evidence does not justify releasing automatic live coaching or prove that a useful automatic coach is impossible.
The owner confirmed that automatic, always-on coaching is Composure's core requirement.
The owner rejected user-requested help as an alternative. Preparation and rehearsal also do not replace the requested product.
The authorized Ministral and Granite comparison is complete. Choose a bounded next experiment or stop.
Do not treat another model download as the default next step.

The [completed comparison](composure-additional-models.results.md) passed no candidate.
Ministral matched Qwen's 14/17 direct Core score. Granite reached 10/17 in evidence mode.
The next recommendation therefore moves to diagnosis and a bounded automatic-coaching experiment.

## What the results establish

The frozen cases test action choice, deliberate silence, bounded wording, and delivery through Composure's cue rules.
They exposed wrong issue classifications, direct questions, unsupported speaker-role assumptions, and blocked later cues.
The same vague-feedback sentence occurs both alone and in the progressing conversation.
These scores do not measure broad real-call accuracy or prove that a generic model cannot learn the task.
Nor do valid JSON and a short response time establish useful advice.

Automatic live coaching combines several difficult decisions: what happened, whether advice helps, whom to address, and when to interrupt.
The current system also lacks verified speaker attribution on its audio routes.
Changing the text model cannot by itself supply missing speaker evidence or establish useful timing.
These are product and pipeline risks as well as model risks.

## Recommended next experiment

If neither new candidate passes, stop further generic model searches and prompt tuning at this checkpoint.
Audit the remaining failures before deciding what to train or redesign.
Distinguish wrong detection from unclear speaker evidence, debatable action labels, unsuitable wording, and delivery suppression.
Preserve existing regression expectations. Record disputed cases separately instead of changing labels to obtain a pass.

The follow-up found both output-contract failures and wrong intervention judgments.
Test a closed observation format with hard-constrained decoding or category scoring before assuming that more model capacity is required.
Select evidence spans from supplied text rather than accepting arbitrary rewritten quotes.
This can address some formatting failures. It cannot establish correct issue detection or useful timing.
Keep any classifier scores untrusted until a separate calibration set supports an intervention threshold.

Then test a smaller set of clearly defined automatic interventions.
The coach still observes an explicitly started session and decides when to display a cue without a manual help request.
A narrower intervention set reduces the number of distinctions the detector must make while preserving automatic operation.
The useful intervention set must follow the audit and a separate evaluation. No current cue type is assumed ready.

Evaluate verified speech-source evidence where advice depends on who spoke.
Microphone and application streams alone do not prove speaker identity on unverified speaker routes.
Use route validation and bounded evidence rules before permitting speaker-dependent advice.
Before a real listening trial, resolve the current native audio-test crash and verify the required audio route.
This is a proposed next experiment. No new detector, training run, speaker promise, or product scope changed in this checkpoint.

## Proposed bounded usefulness trial

Use separate invented complete conversations with routine stretches, genuine cue opportunities, topic changes, and resolved issues.
Include several roles and topics. Do not derive the set by paraphrasing the current development failures.
Have reviewers identify useful cue windows and acceptable advice before generating candidate replies.
Preserve reviewer disagreement and ambiguous cases instead of forcing a single answer where several actions are defensible.
Keep the existing frozen expectations unchanged for their original regression purpose.

Run the complete automatic policy, including abstention, repeated advice, priority, expiry, and cooldown.
Measure useful cues, materially wrong cues, missed useful windows, and end-to-end latency across each conversation.
Judge the displayed cue, not only an internal action label or an isolated model reply.
Keep confidence thresholds separate from self-reported model confidence. Calibrate them on a dedicated set if a detector is trained.
Agree on the usefulness and false-cue thresholds before the trial, then preserve them while scoring candidates.
Propose at most two prototype iterations before a continue-or-stop decision.
This pilot informs a product decision. It does not replace broader release, privacy, fairness, or hardware acceptance checks.

## Continue, narrow, or stop

| Choice | Evidence required | Recommendation |
| --- | --- | --- |
| Continue the current automatic scope | Development, wording, and independent verification pass, followed by useful complete-conversation trials and target-machine measurements. | Continue only if this evidence exists. A model score alone is insufficient. |
| Test fewer automatic intervention types | The error audit identifies learnable, observable distinctions and a bounded trial can test useful automatic timing. | Recommended next experiment if the authorized comparison fails. The user must not request each cue. |
| Train a task-specific detector | Varied reviewed examples, consistent labels, a separate calibration set, and independent evaluation support the proposed distinctions. | A research option with an explicit budget and stop rule, not a promised quality fix. |
| Stop Composure | The bounded automatic-coaching experiment still produces unhelpful or misleading cues, or cannot fit the hardware and privacy limits. | Stopping is a valid product decision. Past effort does not justify further investment by itself. |

## Training and additional models

Fine-tuning remains a later hypothesis, not the next automatic step.
It requires varied reviewed examples, an error taxonomy, independent evaluation, and enough consistent labels to learn the intended distinctions.
The current 17 cases cannot support a credible training or generalization claim.
A small supervised classifier or adapted local model could become an option for a narrowly defined issue set.
Both need the same data and validation discipline. Merely renaming action labels as issue labels did not solve detection.
Combining multiple models also needs a measured benefit. Wording improvements cannot correct a wrong detection by themselves.
Cloud processing remains deferred and would change the product's privacy contract.
