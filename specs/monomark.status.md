<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 59913417-3725-4ef1-8520-025a41a47ea1
Created: 2026
-->

<!-- AGENT: Records MonoMark scope, progress, decisions, and verification limits. -->

# MonoMark status

Updated on 13 November 2026.

The owner requested a fast, read-only monospace Markdown viewer, primarily for macOS.
iPhone and iPad are secondary targets, ideally sharing rendering features.
The owner approved the product baseline and confirmed one left sidebar with Files, Contents, Links, and History tabs.
MonoMark replaces the earlier candidate name MacDownMono.
The owner also requires a switchable window mode and full-screen reading limited to the current display.
The brief now follows documented Pages and platform shortcuts, including different reading-navigation rules on Mac and mobile.
This correction removes speculative bindings and Escape-driven closure of ordinary document windows. Native Close handles tabs and windows.
Multi-display and keyboard acceptance checks remain planned until an application prototype exists.

New refinements require persistent per-file reading state, complete machine-local history, document tabs, and bounded local link previews.
Durable state belongs in Application Support. Disposable renderer caches remain independently bounded and purgeable.
The large-document plan covers safe mapping or bounded reads, source-aware indexing, virtualized rendering, complete search, and printing.
Zed source review found distinct headers, alternating body rows, and themed grid lines, without column banding in the inspected path.
MonoMark adds optional column banding as its own design choice. No running Zed interface or MonoMark table renderer was tested.

The [product brief](monomark.product.md) records requirements, proposed behavior, architecture tradeoffs, and a delivery sequence.
The renderer recommendation remains provisional until a bounded prototype measures fidelity and resource use.
Platform floors, supported Mac architectures, performance limits, and several syntax details remain open.

Current work consists only of product documentation. No application source or dependency was added.
The existing documentation profile covers these specifications. Native component configuration must precede implementation.
No application build, performance measurement, device test, or release is claimed.

Repository validation passed: the profile check, 79 Python tests, and 37 shell contract checks.
