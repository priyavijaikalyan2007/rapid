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
The owner confirmed one left sidebar with Files, Contents, and Links tabs.
MonoMark replaces the earlier candidate name MacDownMono.
The owner also requires a switchable window mode and full-screen reading limited to the current display.
The brief defines proposed shortcuts, Escape precedence, printing, focus-aware scrolling, and horizontal panning.
Multi-display and keyboard acceptance checks remain planned until an application prototype exists.

The [product brief](monomark.product.md) records requirements, proposed behavior, architecture tradeoffs, and a delivery sequence.
The renderer recommendation remains provisional until a bounded prototype measures fidelity and resource use.
Platform floors, supported Mac architectures, performance limits, and several syntax details remain open.

Current work consists only of product documentation. No application source or dependency was added.
The existing documentation profile covers these specifications. Native component configuration must precede implementation.
No application build, performance measurement, device test, or release is claimed.

Repository validation passed: the profile check, 79 Python tests, and 37 shell contract checks.
