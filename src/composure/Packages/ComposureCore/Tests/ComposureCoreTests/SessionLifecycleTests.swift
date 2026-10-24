// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f8cc044d-f821-42e3-8052-29b5f51d0d02
// Created: 2026
// COMPONENT: Session lifecycle tests
// PURPOSE: Verify start, stop, failure, retry, and rejected transitions without capture resources.
// RELATES: SessionLifecycle
// FLOW: Requested transition -> pure policy -> accepted state or typed error.

import Testing
@testable import ComposureCore

/// Proves lifecycle sequencing without timers, permissions, or live audio.
struct SessionLifecycleTests
{
    @Test func newSessionIsIdle()
    {
        #expect(SessionLifecycle().state == .idle)
    }

    @Test func inPersonStartReachesListening() throws
    {
        var lifecycle = SessionLifecycle()

        try lifecycle.transition(to: .checkingReadiness)
        try lifecycle.transition(to: .requestingPermissions)
        try lifecycle.transition(to: .starting)
        try lifecycle.transition(to: .listening)

        #expect(lifecycle.state == .listening)
    }

    @Test func remoteStartSelectsSource() throws
    {
        var lifecycle = SessionLifecycle()
        try lifecycle.transition(to: .checkingReadiness)
        try lifecycle.transition(to: .requestingPermissions)
        try lifecycle.transition(to: .selectingAudioSource)

        try lifecycle.transition(to: .starting)

        #expect(lifecycle.state == .starting)
    }

    @Test func idleCannotSkipReadiness()
    {
        var lifecycle = SessionLifecycle()

        #expect(throws: SessionError.invalidTransition)
        {
            try lifecycle.transition(to: .listening)
        }
    }

    @Test func rejectedTransitionPreservesState()
    {
        var lifecycle = SessionLifecycle()
        _ = try? lifecycle.transition(to: .listening)

        #expect(lifecycle.state == .idle)
    }

    @Test func stoppedSessionReturnsToIdle() throws
    {
        var lifecycle = try listeningSession()

        try lifecycle.transition(to: .stopping)
        try lifecycle.transition(to: .idle)

        #expect(lifecycle.state == .idle)
    }

    @Test func failureRequiresCleanupBeforeRetry() throws
    {
        var lifecycle = try listeningSession()
        try lifecycle.transition(to: .failed(.captureUnavailable))

        #expect(throws: SessionError.invalidTransition)
        {
            try lifecycle.transition(to: .checkingReadiness)
        }
    }

    @Test func failedSessionCanStopAndRetry() throws
    {
        var lifecycle = SessionLifecycle()
        try lifecycle.transition(to: .checkingReadiness)
        try lifecycle.transition(to: .failed(.captureUnavailable))
        try lifecycle.transition(to: .stopping)
        try lifecycle.transition(to: .idle)

        try lifecycle.transition(to: .checkingReadiness)

        #expect(lifecycle.state == .checkingReadiness)
    }

    @Test(arguments: [
        CoachSessionState.checkingReadiness,
        .requestingPermissions,
        .selectingAudioSource,
        .starting
    ])
    func setupCanBeCancelled(state: CoachSessionState) throws
    {
        var lifecycle = SessionLifecycle()
        try lifecycle.transition(to: .checkingReadiness)
        if state != .checkingReadiness
        {
            try lifecycle.transition(to: .requestingPermissions)
        }
        if state == .selectingAudioSource || state == .starting
        {
            try lifecycle.transition(to: state)
        }

        try lifecycle.transition(to: .stopping)

        #expect(lifecycle.state == .stopping)
    }

    @Test func coreContractsCrossConcurrencyBoundaries() async
    {
        let state = CoachSessionState.failed(.captureUnavailable)

        let result = await Task.detached
        {
            state
        }.value

        #expect(result == state)
    }

    /// Creates the standard successful start path for independent stop and failure tests.
    private func listeningSession() throws -> SessionLifecycle
    {
        var lifecycle = SessionLifecycle()
        try lifecycle.transition(to: .checkingReadiness)
        try lifecycle.transition(to: .requestingPermissions)
        try lifecycle.transition(to: .starting)
        try lifecycle.transition(to: .listening)
        return lifecycle
    }
}
