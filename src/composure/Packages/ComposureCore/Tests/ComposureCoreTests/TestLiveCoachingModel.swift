// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000022
// Created: 2026
// COMPONENT: Live lifecycle verification
// PURPOSE: Verify session privacy and cancellation with synthetic inputs and controlled services.
// RELATES: LiveSessionCoordinator, LiveTranscriptionSource, LiveCoachingModel
// FLOW: Explicit synthetic session -> events or errors -> deterministic cleanup assertions.

import ComposureCore
import Foundation

actor TestLiveCoachingModel: LiveCoachingModel
{
    var evaluations = 0
    var cancellations = 0
    var lastInput: LiveCoachingInput?
    let delay: Duration
    let status: ModelReadiness
    let fails: Bool
    let returnsNoCue: Bool
    let usesUnknownEvidence: Bool

    init(
        delay: Duration = .zero,
        status: ModelReadiness = .available,
        fails: Bool = false,
        returnsNoCue: Bool = false,
        usesUnknownEvidence: Bool = false
    )
    {
        self.delay = delay
        self.status = status
        self.fails = fails
        self.returnsNoCue = returnsNoCue
        self.usesUnknownEvidence = usesUnknownEvidence
    }

    func readiness() -> ModelReadiness
    {
        status
    }

    func evaluate(_ input: LiveCoachingInput) async throws -> CueProposal?
    {
        evaluations += 1
        lastInput = input
        do
        {
            try await Task.sleep(for: delay)
            if fails
            {
                throw LiveSessionError.invalidCue
            }
            guard !returnsNoCue, let evidence = input.events.last
            else
            {
                return nil
            }
            return try CueProposal(
                kind: .askFirst,
                instruction: "Ask which promotion criteria remain unmet.",
                confidence: 0.9,
                evidenceID: usesUnknownEvidence ? UUID() : evidence.id
            )
        }
        catch
        {
            if error is CancellationError
            {
                cancellations += 1
            }
            throw error
        }
    }
}
