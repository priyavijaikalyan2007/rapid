<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: a5156d44-8cc6-48fd-ae11-61f06b6a9754
Created: 2026
-->

<!-- AGENT: Owner-authorized independent local model comparison and product decision checkpoint. -->

# Ministral and Granite comparison

The owner authorized Ministral and Granite evaluation and asked whether Composure should continue.
The owner then rejected user-requested help as a fallback. Automatic, always-on coaching is the core requirement.
Complete this bounded comparison before another model search or a native integration.
Use Ministral 3 3B Instruct 2512 and Granite 4.1 3B, with pinned four-bit MLX conversions.
Keep the same 17 invented development cases, strict parser, serial inference, and actual Core replay.
Compare both direct output and the existing evidence policy without tuning either policy for a new candidate.
Keep the separate verification set unused unless a candidate passes development and wording review.

## Files and interfaces

- `specs/composure-model-artifacts.json`: add exact public conversion revisions, source metadata, and file hashes.
- `specs/composure-additional-models.results.md` and `.evidence.json`: record complete comparisons, wording review, and the recommendation.
- `specs/composure-next-decision.md`: propose bounded continue, automatic-scope, and stop criteria without a manual-help pivot.
- `specs/composure-model-shortlist.md`, `specs/composure.status.md`, and `specs/README.md`: link measured results and the next decision.
- `CONVERSATION.md` and `agentknowledge/{concepts.yaml,decisions.yaml,history.jsonl}`: record authorization, outcomes, and limits.
- `PROJECT.md`, `ADDITIONAL.md`, and `CHANGELOG.md`: preserve the required automatic goal and record the comparison checkpoint.
- `scripts/composure_benchmark_runtime.py` and `test/test_composure_model_benchmark.py`: change only if a publisher-template
  or supported-runtime incompatibility requires a tested adapter correction. Add a failing regression first.

No pattern required. Existing functions and the injected generation boundary suffice.
The CLI and observation interfaces remain unchanged. No application dependency or production model change is planned.
Downloaded files and intermediate reports stay under ignored `local/composure-benchmark/`.
Verify public file hashes before model loading. Disable implicit credentials, remote model code, and inference networking.
Use the existing bounded six-second request and five-minute worker limits.

## Product decision

Separate evidence about action choice, wording, delivery, and actual usefulness.
The current authored cases do not establish a general model ranking or the viability of every possible product scope.
If neither candidate passes, stop further model shopping at this checkpoint.
Evaluate a narrower set of automatic interventions, stronger source evidence, or a task-specific detector.
Do not substitute user-requested help, preparation, or rehearsal for the accepted always-on product goal.
Any next experiment needs explicit acceptance criteria and a bounded usefulness trial.
Fine-tuning requires varied reviewed examples and a new independent test set. The current 17 cases are insufficient training data.
Keep cloud processing deferred under the existing privacy constraint.
State what evidence would support continuing, narrowing, or stopping the automatic live feature.

## Verification

Run the existing Python and repository checks after adding artifacts and records.
Run focused Core replays and record quality failures without weakening acceptance rules.
Run the full repository command. Keep the previously observed native audio-test crash separate from model quality.
Preserve the owner's Xcode project edit and every frozen evaluation source file.
Commit and push the measured checkpoint under the repository's standing authorization.

## Outcome

Neither candidate passed. Direct Core scores were 14/17 for Ministral and 5/17 for Granite.
Evidence-mode Core scores were 7/17 and 10/17 respectively. Verification remains unused.
The scoped tokenizer correction passed its new boundary tests and a check against the pinned Tekken pattern.
The next proposed stage preserves automatic coaching and stops generic model searches.
Full native validation remains open because of the unchanged audio-test process crash.
