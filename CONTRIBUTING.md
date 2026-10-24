<!--
SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 2cfecb31-03a2-4475-94fc-e1ce890f95c3
Created: 2026
-->

<!-- AGENT: Maintainer-only contribution policy and verified development entry points. -->

# Contributing to rapid

## Contribution model

Code and documentation contributions are limited to repository maintainers.
The project does not accept external pull requests at this time.
Anyone may report a reproducible defect or request a feature through GitHub Issues.
The owner, Outcrop Inc, reviews scope and acceptance before a maintainer implements a change.
The project does not promise a response or release date for an issue.

## Development setup

Read [project facts](PROJECT.md) for prerequisites and component commands.
Read AGENTS.md and the selected guides before changing code.
Write a failing test before implementing software behavior.
Run ./test.sh for the full local validation sequence.
Use ./test.sh repository for repository-only work and ./test.sh web for website-only validation.
Use ./build.sh for the complete unsigned application and website build.
Record results and limitations in the owning status file under specs/.
Keep changes focused, preserve unrelated files, and commit verified changes without an automatic push.

## Reporting bugs

Repository: https://github.com/priyavijaikalyan2007/rapid
Public issues are enabled at https://github.com/priyavijaikalyan2007/rapid/issues.
Include the observed behavior, expected behavior, affected version, and reproduction steps.
Exclude credentials and private customer content.
Report vulnerabilities through [the security policy](SECURITY.md).

## Conduct and licensing

Read [the code of conduct](CODE_OF_CONDUCT.md) and [the project license](<LICENSE>).
Project-owned contributions use GPL-3.0-or-later under the root LICENSE.
Preserve third-party copyright and license notices.
Only include material that the project has permission to distribute under its applicable terms.

## Maintainer source checks

Use the checked-in editor defaults, SwiftFormat rules, and website ESLint rules for future source edits.
The build workflow checks these conventions before it builds the applications.
The conventions remain subject to the full shared instructions. Format checks do not replace review or behavior tests.

1. Install the validation tools with `brew install bats-core swiftformat shellcheck shfmt`.
2. Install locked website tools with `npm ci --prefix src/web --ignore-scripts`.
3. Run `./scripts/check-source-style.sh`.
4. Run `npm run lint --prefix src/web`.
5. Run `./test.sh`.

The audit used SwiftFormat 0.64.1, ShellCheck 0.11.0, shfmt 3.14.1, ESLint 10.13.0, and Node.js 26.
The native and shell checker uses installed tools and never downloads a formatter during validation.
CI installs its tools explicitly. The hosted workflow must still run after an authorized push.
