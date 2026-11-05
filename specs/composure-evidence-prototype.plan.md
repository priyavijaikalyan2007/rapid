<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 27011ee3-8618-4cbb-a760-833c174b6d53
Created: 2026
-->

<!-- AGENT: Bounded evidence-first experiment before native model integration. -->

# Evidence-first local prototype

Resume Qwen3.5-4B under the Mac-only, 16 GB Air constraints. Keep production behavior unchanged during evaluation.
Separate issue detection, application-owned action selection, and cue wording.
Use fixed, reviewed phrases first. Compare Apple-generated wording later only if detection passes.
This staged pipeline differs from a model with internal mixture-of-experts routing.

## Files and interfaces

- `scripts/composure_evidence_policy.py`: add the observation policy, strict parser, and fixed action/wording selection.
- `scripts/composure_model_benchmark.py`: add `--mode direct|evidence`, preserve the direct baseline, and record observations.
- `scripts/composure_benchmark_runtime.py`: accept an application-controlled reply prefix and report that prefix.
- `test/test_composure_evidence_policy.py`: test grounding, output boundaries, action mapping, and driver isolation first.
- `test/test_composure_model_benchmark.py`: test explicit response framing before changing the runtime.
- `specs/composure-evidence-prototype.results.md` and `.evidence.json`: record measured results and remaining gates.
- `specs/composure-model-shortlist.md`: record publisher-backed Hugging Face choices and the Meta Muse finding.
- `src/composure/README.md`: document the optional evidence command and its limits.
- `specs/README.md` and `CHANGELOG.md`: index the experiment and record the optional developer command.
- `specs/composure.status.md`, `CONVERSATION.md`, and `agentknowledge/{concepts.yaml,entities.yaml,decisions.yaml,history.jsonl}`:
  record the request, experiment, evidence, and next gate.

No pattern required. Simple functions and the existing injected generation boundary suffice.
Keep parsing and action rules outside the CLI and inference runtime. Add no runtime dependency.

`parse_observation(text: str, current_speech: str) -> dict` accepts exactly `issue`, `confidence`, and `evidence`.
The closed issue set describes ambiguity, concrete concerns, missing decisions, unsupported certainty, announced reactions,
personal attacks, or no issue. An actionable observation requires a bounded exact quote from current speech.
Silence requires an empty quote. Reject duplicate fields, extra content, invalid numbers, and evidence from older speech.
An exact quote proves text provenance, not that the issue classification is correct.

`select_cue(observation: dict) -> dict` returns the existing closed action contract and reviewed wording.
`run_cases(fixtures, generate, clock, *, mode="direct") -> dict` retains existing default behavior.
Evidence mode uses its own versioned policy and adds a validated observation to each successful record.
Expected labels and case metadata must never enter a model request.

## Sequence and gates

1. Add boundary and integration tests and observe their failure before implementation.
2. Implement evidence mode without changing the frozen development inputs or expected outcomes.
3. Run Qwen3.5-4B on the same 17 cases and replay through the actual Core arbiter.
4. Review wording and observations, including false cues, stale context, and cue suppression.
5. Record failures without changing acceptance labels or weakening cue rules.
6. Run the full repository suite and preserve the owner's existing Xcode project edit.
7. Commit and push the verified prototype and research records under the repository's standing authorization.

Keep the separate eight-case verification set unused until development and wording gates pass.
Use invented inputs, pinned verified local weights, offline inference, serial requests, and the existing six-second deadline.
Keep the existing byte, token, and worker limits. Do not start capture or retain real meeting content.
Reports may retain invented observations and replies. Provider exceptions remain excluded.
No model output reaches a tool, executable sink, authorization decision, or retrieval system.
Training, feedback learning, shared tenant data, embeddings, and confidential system prompts are absent from this experiment.
Supply-chain checks, independent validation, quality review, and resource bounds remain required.
New model choices require pinned artifacts and runtime support before any benchmark or adoption claim.

## Recorded outcome

Both policy revisions failed development quality checks. The second revision passed 14/17 Core replay checks.
The fresh direct baseline also passed 14/17 Core checks. The verification set remains unused.
Python, shell, website, style, and Core checks passed. Full validation hit an unchanged native audio test crash.
See the [results](composure-evidence-prototype.results.md) for the measured limits and the next comparison gate.
