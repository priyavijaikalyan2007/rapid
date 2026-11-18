// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 87cfbfab-4187-4b91-9b01-e25c31dccfda
// COMPONENT: Renderer recovery regression tests
// PURPOSE: Prevent repeated helper failures from creating an unbounded restart loop.
import Testing
@testable import MonoMarkCore

struct RendererRecoveryTests
{
    @Test func stopsAfterTwoRapidRetries()
    {
        var recovery = RendererRecovery()
        let results = [100.0, 101.0, 102.0].map
        {
            recovery.permitsReload(at: $0)
        }
        #expect(results == [true, true, false])
    }

    @Test func explicitRetryResetsTheBudget()
    {
        var recovery = RendererRecovery()
        _ = recovery.permitsReload(at: 100)
        _ = recovery.permitsReload(at: 101)
        recovery.reset()
        let allowed = recovery.permitsReload(at: 102)
        #expect(allowed)
    }

    @Test func stableIntervalRestoresTheBudget()
    {
        var recovery = RendererRecovery()
        _ = recovery.permitsReload(at: 100)
        _ = recovery.permitsReload(at: 101)
        let allowed = recovery.permitsReload(at: 162)
        #expect(allowed)
    }

    @Test func invalidTimeCannotStartARetry()
    {
        var recovery = RendererRecovery()
        let allowed = recovery.permitsReload(at: .nan)
        #expect(!allowed)
    }
}
