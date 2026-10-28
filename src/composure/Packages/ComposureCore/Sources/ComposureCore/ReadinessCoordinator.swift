// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a8de2a27-e7d5-46bc-97a8-4bd6c3b0cb03
// Created: 2026
// COMPONENT: Device readiness
// PURPOSE: Inspect prerequisites and keep explicitly requested setup separate from capture.
// RELATES: ReadinessCoordinator, ReadinessProvider
// FLOW: Native prerequisite observation -> typed readiness -> explicit setup and refresh.

import Foundation
import Observation

/// Shared across app windows. The system can continue asset downloads after an app operation ends.
@MainActor
@Observable
public final class ReadinessCoordinator
{
    public private(set) var snapshot = DeviceReadiness()
    public private(set) var isBusy = false
    public private(set) var isSettingUp = false
    public private(set) var progress: Double?
    public private(set) var error: ReadinessError?
    private let provider: any ReadinessProvider
    private let logger: DiagnosticLogger
    private var operationID: UUID?

    public init(provider: any ReadinessProvider, logger: DiagnosticLogger = DiagnosticLogger { _, _ in })
    {
        self.provider = provider
        self.logger = logger
    }

    /// Does not request permission, reserve assets, install models, or start audio.
    public func refresh() async
    {
        guard !isBusy
        else
        {
            return
        }
        isBusy = true
        defer { isBusy = false }
        let updated = await provider.snapshot()
        guard !Task.isCancelled
        else
        {
            return
        }
        snapshot = updated
        if updated.speech == .ready
        {
            error = nil
        }
        logger.record(.readinessChecked)
    }

    /// Call only after an explicit setup action. Completion always rechecks actual asset status.
    public func setUpSpeech() async
    {
        guard !isBusy
        else
        {
            return
        }
        isBusy = true
        isSettingUp = true
        error = nil
        let id = UUID()
        operationID = id
        defer { finishSetup() }
        do
        {
            try await install(id: id)
        }
        catch
        {
            await recordFailure(error)
        }
    }

    private func recordFailure(_ failure: any Error) async
    {
        guard !Task.isCancelled, !(failure is CancellationError)
        else
        {
            return
        }
        let updated = await provider.snapshot()
        guard !Task.isCancelled
        else
        {
            return
        }
        error = failure as? ReadinessError ?? .installationFailed
        snapshot = updated
        logger.record(.speechSetupFailed)
    }

    private func install(id: UUID) async throws
    {
        let before = await provider.snapshot()
        try Task.checkCancellation()
        snapshot = before
        guard before.speech.canSetUp
        else
        {
            return
        }
        logger.record(.speechSetupStarted)
        try await provider.setUpSpeech
        { [weak self] fraction in
            await self?.updateProgress(fraction, id: id)
        }
        try Task.checkCancellation()
        let updated = await provider.snapshot()
        try Task.checkCancellation()
        snapshot = updated
        logger.record(.speechSetupCompleted)
    }

    private func updateProgress(_ fraction: Double?, id: UUID)
    {
        guard operationID == id
        else
        {
            return
        }
        guard let fraction, fraction.isFinite
        else
        {
            progress = nil
            return
        }
        progress = min(1, max(0, fraction))
    }

    private func finishSetup()
    {
        operationID = nil
        isBusy = false
        isSettingUp = false
        progress = nil
    }
}
