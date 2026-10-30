// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000006
// Created: 2026
// COMPONENT: Content-free live diagnostics tests
// PURPOSE: Distinguish deliberate silence from missing input or rejected work without retaining meeting text.
// RELATES: LiveSessionDiagnostics, LiveSessionCoordinator
// FLOW: Numeric pipeline events -> bounded counts and closed outcomes -> explicit session cleanup.

import Testing
@testable import ComposureCore

struct LiveSessionDiagnosticsTests
{
    @Test func resultCountersDistinguishPartialsFinalsAndAcceptedFinals()
    {
        var diagnostics = LiveSessionDiagnostics()
        diagnostics.recordSpeech(isFinal: false, accepted: true)
        diagnostics.recordSpeech(isFinal: true, accepted: true)
        diagnostics.recordSpeech(isFinal: true, accepted: false)
        #expect(diagnostics.results == 3)
        #expect(diagnostics.finalResults == 2)
        #expect(diagnostics.acceptedFinalResults == 1)
    }

    @Test func counterGrowthIsBounded()
    {
        var diagnostics = LiveSessionDiagnostics()
        for _ in 0 ..< 20_000
        {
            diagnostics.recordCheck()
        }
        #expect(diagnostics.checks == 10_000)
    }

    @Test func suppressionRecordsOnlyAClosedReason()
    {
        var diagnostics = LiveSessionDiagnostics()
        diagnostics.recordSuppression(.staleEvidence)
        #expect(diagnostics.withheld == 1)
        #expect(diagnostics.outcome == .withheld(.staleEvidence))
    }
}
