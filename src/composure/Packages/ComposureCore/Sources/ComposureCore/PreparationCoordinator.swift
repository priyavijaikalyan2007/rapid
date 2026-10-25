// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: e667f586-adb6-4338-9d5e-70c62c8668c6
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Keep UI state transient and suppress late results after cancellation or clearing.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

import Foundation
import Observation

/// Holds transient fields only. Identity checks prevent canceled work from publishing stale content.
@MainActor
@Observable
public final class PreparationCoordinator
{
    public var topic = ""
    {
        didSet
        {
            if oldValue != topic
            {
                cancel()
            }
        }
    }

    public var outcome = ""
    {
        didSet
        {
            if oldValue != outcome
            {
                cancel()
            }
        }
    }

    public var concern = ""
    {
        didSet
        {
            if oldValue != concern
            {
                cancel()
            }
        }
    }

    public var highStakes = false
    {
        didSet
        {
            if oldValue != highStakes
            {
                cancel()
            }
        }
    }

    public private(set) var result: PreparationResult?
    public private(set) var error: PreparationError?
    public private(set) var isPreparing = false
    public private(set) var readiness: ModelReadiness = .otherUnavailable
    private let service: PreparationService
    private let logger: DiagnosticLogger
    private var requestID: UUID?
    private var work: Task<PreparationResult, any Error>?

    public init(service: PreparationService, logger: DiagnosticLogger = DiagnosticLogger { _, _ in })
    {
        self.service = service
        self.logger = logger
    }

    public func refreshReadiness() async
    {
        let status = await service.readiness()
        guard !Task.isCancelled
        else
        {
            return
        }
        readiness = status
    }

    public func prepare(profile: CoachingProfile) async
    {
        guard !isPreparing
        else
        {
            return
        }
        do
        {
            let input = try MeetingPreparationInput(
                topic: topic,
                outcome: outcome,
                concern: concern,
                highStakes: highStakes
            )
            await run(input, profile: profile)
        }
        catch
        {
            self.error = error as? PreparationError ?? .generationFailed
        }
    }

    private func run(_ input: MeetingPreparationInput, profile: CoachingProfile) async
    {
        let id = UUID()
        requestID = id
        isPreparing = true
        result = nil
        error = nil
        logger.record(.preparationStarted)
        let service = service
        let operation = Task
        {
            try await service.prepare(input, profile: profile)
        }
        work = operation
        await withTaskCancellationHandler
        {
            do
            {
                let prepared = try await operation.value
                try Task.checkCancellation()
                finish(prepared, id: id)
            }
            catch
            {
                fail(error, id: id)
            }
        }
        onCancel: {
            operation.cancel()
        }
    }

    private func finish(_ result: PreparationResult, id: UUID)
    {
        guard requestID == id
        else
        {
            return
        }
        self.result = result
        isPreparing = false
        work = nil
        requestID = nil
        logger.record(.preparationCompleted)
    }

    private func fail(_ failure: any Error, id: UUID)
    {
        guard requestID == id
        else
        {
            return
        }
        isPreparing = false
        work = nil
        requestID = nil
        if !(failure is CancellationError)
        {
            error = failure as? PreparationError ?? .generationFailed
        }
        logger.record(.preparationCanceled)
    }

    /// Cancels work and invalidates output while preserving the editable input.
    public func cancel()
    {
        requestID = nil
        work?.cancel()
        work = nil
        isPreparing = false
        result = nil
        error = nil
    }

    /// Used for explicit Clear and the mobile privacy lifecycle. Swift strings do not promise zeroization.
    public func clear()
    {
        cancel()
        topic = ""
        outcome = ""
        concern = ""
        highStakes = false
    }
}
