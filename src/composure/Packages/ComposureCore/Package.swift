// swift-tools-version: 6.0
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 26654263-8223-45fe-a60c-7ae4d3030f49
// Created: 2026
// COMPONENT: ComposureCore package
// PURPOSE: Share pure core rules and isolate the native Apple model adapter in a separate target.
// RELATES: Composure.xcodeproj
// FLOW: Package manifest -> core module -> native applications and tests.

import PackageDescription

let package = Package(
    name: "ComposureCore",
    platforms: [.macOS("26.0"), .iOS("26.0")],
    products: [
        .library(name: "ComposureCore", targets: ["ComposureCore"]),
        .library(name: "ComposureModels", targets: ["ComposureModels"])
    ],
    targets: [
        .target(name: "ComposureCore"),
        .testTarget(name: "ComposureCoreTests", dependencies: ["ComposureCore"]),
        .target(name: "ComposureModels", dependencies: ["ComposureCore"]),
        .testTarget(name: "ComposureModelsTests", dependencies: ["ComposureCore", "ComposureModels"])
    ],
    swiftLanguageModes: [.v6]
)
