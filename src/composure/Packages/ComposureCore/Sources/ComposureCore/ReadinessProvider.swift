// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 750c66e6-b487-42ef-b1eb-7d85719df7e9
// Created: 2026
// COMPONENT: Device readiness
// PURPOSE: Inspect prerequisites and keep explicitly requested setup separate from capture.
// RELATES: ReadinessCoordinator, ReadinessProvider
// FLOW: Native prerequisite observation -> typed readiness -> explicit setup and refresh.

/// Separates passive inspection from explicit setup. Neither operation captures meeting content.
public protocol ReadinessProvider: Sendable
{
    func snapshot() async -> DeviceReadiness
    func setUpSpeech(progress: @escaping @Sendable (Double?) async -> Void) async throws
}
