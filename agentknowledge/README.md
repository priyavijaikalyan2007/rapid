<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: d988705e-d405-4365-80d7-0a84d4171b9c
Created: 2026
-->

<!-- AGENT: Explains the evidence-backed knowledge files and ignored local search index. -->

# Repository knowledge

These records were reconstructed from source, existing documentation, Git history, and explicit owner decisions on 23 October 2026.
They describe the current checkout. They do not prove that an application build or release passed.

Start with concepts.yaml for code locations, entities.yaml for models, and decisions.yaml for constraints and design records.
The YAML files use JSON-compatible syntax so Python can validate them without another package.
JSON is a restricted YAML representation. Do not add YAML tags or comments to these three files.
Store explanations here or inside record fields.

The date on a reconstructed decision is its recording date, not its original decision date.
Accepted records come from explicit project instructions or owner answers.
Observed records describe existing code. Planned records describe unimplemented requirements.
Append task summaries to history.jsonl. Do not rewrite previous entries.
Use [the status index](../specs/README.md) for build results and outstanding work.

## Local search index

The shared index scripts were copied from the local instructions repository and retain their upstream MIT notices.
The project adds Swift, JavaScript modules, history records, Python, Bats, and Xcode text formats to the default search scope.
The default exclusions cover local tooling, generated output, agent configuration, and credential directories.
The index is a local search cache. It does not replace the knowledge records.

Run these commands from the repository root:

```sh
python3 scripts/repo-index.py build
python3 scripts/repo-index.py status
python3 scripts/repo-index.py search LocalPhotoProcessor --limit 5
```

The database resides at local/repo-index.sqlite and is ignored by Git.
Use rebuild after source changes. The copied implementation does not support the update command listed in the shared guide.
Custom environment overrides can change the index scope. Review overrides before indexing private files.
Only files no larger than 1,000,000 bytes enter the default index.
