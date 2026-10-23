<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 52ef23fe-2992-45a5-b177-dd152ad741b5
Created: 2026
-->

<!-- AGENT: Defines the setup changes and verification gates before implementation. -->

# Repository setup plan

Date: 23 October 2026.

Complete the existing setup without changing application behavior or publishing a release.
Use configure.sh for component selection and managed instruction routing.
Keep existing platform source locations and the Codex role assignments.

## Files in scope

- Configuration: PROJECT_PROFILE.md, AGENTS.md, PROJECT.md, ADDITIONAL.md, SETUP.md, and .instructions/INITIALIZATION.json if licensing changes.
- Operations: test.sh, run.sh, package.sh, smoke.sh, deploy.sh, and .gitignore.
- Continuous integration: .github/workflows/build.yml runs repository checks before the existing full build.
- Reused index tools: scripts/repo-index.py, scripts/repo_index_lib.py, and scripts/repo-index.sh.
- Tests: test/repository-operations.bats, test/test_repo_index.py, and test/test_repository_knowledge.py.
- Knowledge: agentknowledge/README.md, concepts.yaml, entities.yaml, decisions.yaml, and history.jsonl.
- Status: specs/README.md, repository.status.md, cropprint.status.md, website.status.md, and composure.status.md.
- Documentation: README.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, THIRD_PARTY_NOTICES.md, CHANGELOG.md, and CONVERSATION.md.
- License consistency: src/cropprint/README.md and LICENSE, subject to the owner's license choice.
- Application license text: src/cropprint/LICENSE, src/cropprint/AppStore/metadata.md, and src/cropprint/CropPrint/Views/InformationViews.swift.
- Private security contact: src/web/site/security.txt and src/web/site/.well-known/security.txt, subject to the owner's contact choice.
- Website validation and contact documentation: src/web/scripts/check-site.mjs and src/web/README.md.
- Composure links: src/composure/implementation-plan.md.
- Composure normative cross-reference: src/composure/implementation-specification.md.

## Interfaces and boundaries

test.sh accepts all, repository, cropprint, or web. The default is all.
Repository checks validate configuration, knowledge records, index helpers, and shell command contracts.
run.sh web starts the existing local website preview. Native development uses Xcode.
package.sh macos invokes only the unsigned development packager.
smoke.sh web validates the generated static site locally.
deploy.sh requires --dry-run or an explicit deploy argument. Setup only exercises the dry run when its dependencies are available.
Unknown or extra arguments return status 2 before a component starts.
Component failures preserve a nonzero exit status.

No pattern required - simple function/class suffices.
The root scripts only route commands. Existing application services retain their processing logic.
The index reuses the shared implementation and keeps its database under ignored local/ storage.
No runtime database, cloud AI, telemetry, or application dependency is introduced.

## Sequence and acceptance

1. Read the configuration and existing component contracts.
2. Capture a passing website baseline.
3. Write and run failing command, index, and knowledge checks.
4. Preview and apply corrected profile selections through configure.sh.
5. Implement root routing and bootstrap evidence-backed knowledge records.
6. Complete policy text after the owner answers the pending questions.
7. Run repository checks and relevant application validation.
8. Build and query the ignored local search index.
9. Record results, remaining owner decisions, and verification limits.
10. Commit the setup locally without a push.

The baseline website build passed and validated six HTML files.
Use evidence from current source and Git history for knowledge records.
Label reconstructed decisions and planned work. Do not invent historical decision dates or test results.
