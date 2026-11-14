<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 59913417-3725-4ef1-8520-025a41a47ea1
Created: 2026
-->

<!-- AGENT: Records MonoMark scope, progress, decisions, and verification limits. -->

# MonoMark status

Updated on 14 November 2026.

MonoMark now has native Mac and iPhone/iPad projects under src/app/monomark.
The first implementation includes document tabs, Files/Contents/Links/History navigation, SQLite reading state,
local previews, per-document typography, a bounded worker-based renderer, complex Markdown, and single-display presentation.
Artifact controls copy source, CSV/TSV/pipe-separated data, or PNG renderings. Appearance offers System, Light, and Dark.
HTML comments are hidden outside literal code. Original Markdown remains unchanged by reading and copy operations.

## Verification

Native-core tests, renderer tests, repository checks, and unsigned active/universal Mac and mobile builds pass.
The Mac executable contains arm64 and x86_64. The initial app bundle is about 9.5 MiB on this host.
Real WebKit smoke evidence shows math, tables, and Mermaid, with 15 mounted blocks for a 16-block fixture.
The [native smoke evidence](monomark.smoke.json) now verifies dark rendering, artifact controls, and successful PNG output.
Visual inspection confirms that exported diagram labels and connector colors remain readable in dark mode.
The regression suite uses real Mermaid output and checks label text after sanitization.
Measured renderer line coverage is 98.35% for loaded renderer modules. Native-core line coverage is 94.98%.

The synthetic [indexing evidence](monomark.benchmark.json) records about 487 ms for 10 MiB on this 64 GiB development host.
The Node process RSS after that run was about 264 MB. This is not complete-app or reference-machine performance acceptance.
Inline token graphs are now discarded after each rendered block, reducing retained intermediate work.

The full repository run still fails in unchanged ComposureModelsTests with signal 5.
The MonoMark UI runner could not execute tests because unsigned startup was killed and ad hoc loading reported a Team ID mismatch.
The host's CoreSimulator service is older than the installed Xcode framework, so mobile launch is unverified despite successful compilation.
Physical devices, multiple physical displays, idle energy, and reference-machine acceptance remain unverified.

## Current limits and next stage

The [application guide](../src/app/monomark/README.md) records explicit source, object, image, and print limits.
Cross-viewport selection and very large single-table rendering need further acceptance work.
The owner subsequently authorized highlights, comments, a right sidebar, reading notes, and explicit export into a generated Markdown section.
That work is a separate implementation stage after the reader/copy/appearance commit.
The export command will be named “Export Notes and Annotations to This File.” App-local notes save automatically.
Save and Command-S remain unassigned, and a separate Export a Copy action preserves the original source.

## GitHub tracking

The [MonoMark epic](https://github.com/priyavijaikalyan2007/rapid/issues/1) contains seven features and twenty task or bug issues.
The [issue map](monomark.issues.json) records the hierarchy. Implementation and acceptance status remain distinct.
Palette customization is also recorded in the epic and product specification.
