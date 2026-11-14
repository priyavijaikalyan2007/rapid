// swift-tools-version: 6.0
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: d634aba2-b83e-4220-b133-6fcb4077abb1
// Created: 2026
// COMPONENT: MonoMark native core package
// PURPOSE: MonoMark native core package.
// RELATES: specs/monomark.implementation.md
// FLOW: Input -> validated processing -> result.

import PackageDescription
let package = Package(
    name: "MonoMarkCore",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [.library(name: "MonoMarkCore", targets: ["MonoMarkCore"])],
    targets: [
        .target(name: "MonoMarkCore", path: "apple/Core", linkerSettings: [.linkedLibrary("sqlite3")]),
        .testTarget(name: "MonoMarkCoreTests", dependencies: ["MonoMarkCore"], path: "apple/Tests")
    ]
)
