<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: d513678d-6a2e-46b9-afb1-d4118df0f835
Created: 2026
-->

<!-- AGENT: Separates Composure planning documents from implemented application work. -->

# Composure status

Reviewed on 23 October 2026.

Composure is planned. Its directory contains three specification and planning documents.
No Xcode project, Swift package, application source, or test target exists there.
The profile includes these documents as documentation, not an implemented native application.

The [normative specification](../src/composure/implementation-specification.md) is the implementation contract.
The [product specification](../src/composure/product-specification.md) explains the product and design.
The [implementation plan](../src/composure/implementation-plan.md) defines milestones and acceptance gates.

Before implementation, confirm supported devices and operating systems against actual Apple APIs.
Enable a native component with explicit planned source paths through configure.sh before creating its application structure.
Preserve the specification's on-device processing, explicit listening controls, and transient session-data requirements.

## Source audit on 24 October 2026

The source audit reviewed all three planning documents on 24 October 2026.
The changes add notices, clarify wording, reflow prose, and format illustrative Swift examples.
The normative product requirements remain planned. No Composure app was implemented or tested.
