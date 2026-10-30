// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000026
// Created: 2026
// COMPONENT: Live coaching quality controls
// PURPOSE: Preserve bounded useful context and explain silence without retaining meeting content.
// RELATES: LiveSessionCoordinator, LiveCoachingInput, CueArbiter
// FLOW: Current speech -> validated candidate -> reasoned arbitration -> transient diagnostics and cleanup.

/// All counters saturate at 10,000. The owning coordinator replaces this value on Start and Stop.
public struct LiveSessionDiagnostics: Sendable, Equatable
{
    public private(set) var results = 0
    public private(set) var finalResults = 0
    public private(set) var acceptedFinalResults = 0
    public private(set) var checks = 0
    public private(set) var noCue = 0
    public private(set) var failures = 0
    public private(set) var withheld = 0
    public private(set) var shown = 0
    public private(set) var outcome: LiveCoachingOutcome = .notListening

    public init()
    {
    }

    public mutating func begin()
    {
        self = LiveSessionDiagnostics()
        outcome = .waitingForSpeech
    }

    public mutating func recordSpeech(isFinal: Bool, accepted: Bool)
    {
        increment(\.results)
        if isFinal
        {
            increment(\.finalResults)
        }
        if isFinal && accepted
        {
            increment(\.acceptedFinalResults)
        }
    }

    public mutating func recordCheck()
    {
        increment(\.checks)
        outcome = .evaluating
    }

    public mutating func recordNoCue()
    {
        increment(\.noCue)
        outcome = .noAction
    }

    public mutating func recordFailure()
    {
        increment(\.failures)
        outcome = .failed
    }

    public mutating func recordShown()
    {
        increment(\.shown)
        outcome = .displayed
    }

    public mutating func recordSuppression(_ reason: CueSuppressionReason)
    {
        increment(\.withheld)
        outcome = .withheld(reason)
    }

    private mutating func increment(_ counter: WritableKeyPath<Self, Int>)
    {
        self[keyPath: counter] = min(self[keyPath: counter] + 1, 10_000)
    }
}
