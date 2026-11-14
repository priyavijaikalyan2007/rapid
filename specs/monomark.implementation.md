<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 1032d5e8-8419-42b3-b343-1e49a760ed6a
Created: 2026
-->
<!-- AGENT: Implementation boundaries, interfaces, files, test sequence, and evidence for MonoMark. -->

# MonoMark implementation plan

The owner authorized implementation on 13 November 2026.
Initial deployment targets are macOS 15 and iOS/iPadOS 18. Mac supports Apple silicon and Intel.
Use SwiftUI with AppKit/UIKit adapters and a bundled offline WebKit renderer.
Use native Mac document-window tabs, adaptive mobile navigation, and native menu commands.

## Construction and boundaries

Native core files under `src/app/monomark/apple/Core/` define DocumentLocation, LinkPolicy, ReadingState,
ReaderPreferences, HistoryStore, DocumentAccess, FolderEntry, and PreviewLoader.
HistoryStore uses platform SQLite transactions and a versioned schema for durable, paged history.
DocumentAccess validates scope, source size, provider availability, identity, and coordinated file reads.
LinkPolicy resolves a destination to a fragment, permitted file, external address, or denied action.
PreviewLoader reads a bounded prefix and never records a history visit.

Native UI files under `apple/Shared/` define ReaderSession, ReaderView, ReaderWebView, ResourceHandler,
ReaderSettings, and SidebarView. `apple/Mac/` owns the application delegate, window controller, and native menus.
`apple/Mobile/` owns the SwiftUI entry point and native document picker.
`apple/MonoMark.xcodeproj/`, application property lists, and entitlements define explicit platform targets.
`Package.swift` and `apple/Tests/` exercise the native core independently of views.

Renderer files under `renderer/src/` define parser, parser worker, document host, virtual viewport,
sanitization, deferred objects, preferences, selection, find, print, and bridge handling.
One authoritative Markdown token stream produces HTML blocks, headings, object anchors, and link occurrences.
The worker owns parsing and complete-document indexing. The host mounts nearby blocks with bounded expensive resources.
The WebKit Adapter and native file-access Adapter isolate platform APIs. Direct value types suffice for other core rules.
SQLite serializes writes. Native generations and worker termination prevent old document results from replacing new state.

Public contracts include `LinkPolicy.resolve(_:relativeTo:root:)`, `HistoryStore.record(_:)`,
`HistoryStore.page(query:offset:limit:)`, `HistoryStore.forget(_:)`, and `PreviewLoader.load(_:root:)`.
The renderer accepts load, preferences, jump, find, zoom, and print commands.
It emits ready, index, position, navigation, preview, failure, and print-ready messages.
Native code validates messages and grants file access. Documents cannot grant privileges through rendered HTML.

Other files include renderer package manifests, build scripts and tests, component build.sh and clean.sh,
README.md, root command routing tests, PROJECT_PROFILE.md, PROJECT.md, specs, and agent knowledge records.
Generated renderer bundles and Xcode outputs remain under the component's ignored build directory.
Bundled third-party license texts accompany packaged resources and are indexed in THIRD_PARTY_NOTICES.md.

## Verification sequence

Write and run failing native tests for link scope, source bounds, history recovery, preferences, and previews.
Write and run failing renderer tests for duplicate headings, object outlines, reference links, math, code, emoji,
unsafe URLs, HTML sanitization, chunk semantics, virtualization, and distant search.
Implement each tested contract and extend failure tests before adding new behavior.
Run native and JavaScript coverage and inspect packaged resources and offline loading.
Compile Mac active and generic destinations and iOS simulator and device targets without signing.
Run a real WebKit smoke check and synthetic large-document benchmarks before recording architecture acceptance.
Run repository regression and source checks. Record existing failures separately from MonoMark failures.
Verify native interactions where the host permits. Multi-display and physical-device claims require direct evidence.

The prototype must report source bytes, block count, parse duration, first visible content, resident memory,
and retained mounted blocks. These observations do not establish performance on an untested reference machine.
