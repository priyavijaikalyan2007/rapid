// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000023
// Created: 2026
// COMPONENT: Live lifecycle verification
// PURPOSE: Verify session privacy and cancellation with synthetic inputs and controlled services.
// RELATES: LiveSessionCoordinator, LiveTranscriptionSource, LiveCoachingModel
// FLOW: Explicit synthetic session -> events or errors -> deterministic cleanup assertions.

import Foundation
import Testing
@testable import ComposureCore

@MainActor
struct LiveSessionCoordinatorTests
{
    @Test func pipelineCountersClearOnStop() async throws
    {
        let source = TestLiveTranscriptionSource()
        let coordinator = make(source: source)
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        source.receive?(try speech(final: false))
        source.receive?(try speech(final: true))
        await coordinator.tick()
        await settle
        {
            coordinator.cue != nil
        }
        #expect(coordinator.diagnostics.results == 2)
        #expect(coordinator.diagnostics.acceptedFinalResults == 1)
        #expect(coordinator.diagnostics.checks == 1)
        #expect(coordinator.diagnostics.shown == 1)
        await coordinator.stop()
        #expect(coordinator.diagnostics == LiveSessionDiagnostics())
    }

    @Test func noCueDecisionIsDifferentFromFailedProcessing() async throws
    {
        let source = TestLiveTranscriptionSource()
        let coordinator = make(source: source, model: TestLiveCoachingModel(returnsNoCue: true))
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        source.receive?(try speech(final: true))
        await coordinator.tick()
        await settle
        {
            coordinator.diagnostics.noCue == 1
        }
        #expect(coordinator.diagnostics.failures == 0)
        #expect(coordinator.diagnostics.outcome == .noAction)
        await coordinator.stop()
    }

    @Test func unsupportedEvidenceIsVisibleAsAContentFreeRejection() async throws
    {
        let source = TestLiveTranscriptionSource()
        let coordinator = make(source: source, model: TestLiveCoachingModel(usesUnknownEvidence: true))
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        source.receive?(try speech(final: true))
        await coordinator.tick()
        await settle
        {
            coordinator.diagnostics.withheld == 1
        }
        #expect(coordinator.cue == nil)
        #expect(coordinator.diagnostics.outcome == .withheld(.invalidEvidence))
        await coordinator.stop()
    }

    @Test func nextOpportunityReceivesBoundedRecentAdvice() async throws
    {
        let source = TestLiveTranscriptionSource()
        let model = TestLiveCoachingModel()
        let clock = TestLiveClock()
        let coordinator = LiveSessionCoordinator(
            source: source,
            model: model,
            clock: {
                clock.now
            },
            automaticallyTicks: false
        )
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        source.receive?(try speech(final: true))
        await coordinator.tick()
        await settle
        {
            coordinator.diagnostics.shown == 1
        }
        clock.now = 140
        source.receive?(try TranscriptEvent(
            channel: .meeting,
            startSeconds: 137,
            endSeconds: 139,
            text: "Who owns the follow-up review and date?",
            isFinal: true
        ))
        await coordinator.tick()
        await settle
        {
            coordinator.diagnostics.withheld == 1
        }
        #expect(await model.lastInput?.recentCues.count == 1)
        await coordinator.stop()
    }

    @Test func deadlineCancelsModelWorkAndKeepsCaptureAvailable() async throws
    {
        let source = TestLiveTranscriptionSource()
        let model = TestLiveCoachingModel(delay: .seconds(30))
        let coordinator = LiveSessionCoordinator(
            source: source,
            model: model,
            clock: {
                100
            },
            automaticallyTicks: false,
            timeout: .milliseconds(1)
        )
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        source.receive?(try speech(final: true))
        await coordinator.tick()
        await settle
        {
            coordinator.modelFailureCount == 1
        }
        #expect(await model.cancellations == 1)
        #expect(coordinator.state == .listening)
        #expect(coordinator.cue == nil)
        await coordinator.stop()
    }

    @Test func canceledPickerReturnsToIdleWithoutAnError() async
    {
        let source = TestLiveTranscriptionSource()
        source.cancelsSelection = true
        let coordinator = make(source: source)
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .idle || coordinator.state == .failed
        }
        #expect(coordinator.state == .idle)
        #expect(coordinator.error == nil)
    }

    @Test func initializationIsPassive() async
    {
        let source = TestLiveTranscriptionSource()
        _ = make(source: source)
        #expect(source.startCount == 0)
    }

    @Test func duplicateStartUsesOneCaptureSession() async
    {
        let source = TestLiveTranscriptionSource()
        let coordinator = make(source: source)
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        #expect(source.startCount == 1)
        await coordinator.stop()
    }

    @Test func onlyFinalMeaningfulSpeechCanProduceCue() async throws
    {
        let source = TestLiveTranscriptionSource()
        let coordinator = make(source: source)
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .difficultConversation)
        await settle
        {
            coordinator.state == .listening
        }
        source.receive?(try speech(final: false))
        await coordinator.tick()
        #expect(coordinator.cue == nil)
        source.receive?(try speech(final: true))
        await coordinator.tick()
        await settle
        {
            coordinator.cue != nil
        }
        #expect(coordinator.cue?.kind == .askFirst)
        await coordinator.stop()
    }

    @Test func stopClearsContentAndRejectsLateEvents() async throws
    {
        let source = TestLiveTranscriptionSource()
        let coordinator = make(source: source)
        coordinator.objective = "Synthetic promotion objective"
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        let lateCallback = source.receive
        source.receive?(try speech(final: true))
        await coordinator.tick()
        await coordinator.stop()
        lateCallback?(try speech(final: true))
        #expect(coordinator.retainedEventCount == 0)
        #expect(coordinator.objective.isEmpty)
        #expect(coordinator.cue == nil)
        #expect(coordinator.state == .idle)
    }

    @Test func oldSessionCannotWriteIntoNewSession() async throws
    {
        let source = TestLiveTranscriptionSource()
        let coordinator = make(source: source)
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        let lateCallback = source.receive
        await coordinator.stop()
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        lateCallback?(try speech(final: true))
        #expect(coordinator.retainedEventCount == 0)
        await coordinator.stop()
    }

    @Test func unconfirmedStopBlocksRestartUntilRetrySucceeds() async
    {
        let source = TestLiveTranscriptionSource()
        let coordinator = make(source: source)
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        source.confirmsStop = false
        await coordinator.stop()
        #expect(!coordinator.canStart)
        #expect(coordinator.error == .stopUnconfirmed)
        #expect(coordinator.state == .stopUnconfirmed)
        source.confirmsStop = true
        await coordinator.stop()
        #expect(coordinator.canStart)
    }

    @Test func sourceFailureStopsAndClearsContext() async throws
    {
        let source = TestLiveTranscriptionSource()
        let coordinator = make(source: source)
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        source.receive?(try speech(final: true))
        source.reportFailure?(.captureFailed)
        await settle
        {
            coordinator.state == .failed
        }
        #expect(coordinator.retainedEventCount == 0)
        #expect(source.stopCount == 1)
    }

    @Test func canceledGenerationCannotPublishAfterStop() async throws
    {
        let source = TestLiveTranscriptionSource()
        let model = TestLiveCoachingModel(delay: .seconds(30))
        let coordinator = make(source: source, model: model)
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        source.receive?(try speech(final: true))
        await coordinator.tick()
        for _ in 0 ..< 2000
        {
            if await model.evaluations > 0
            {
                break
            }
            await Task.yield()
        }
        await coordinator.stop()
        #expect(await model.cancellations == 1)
        #expect(coordinator.cue == nil)
    }

    @Test func unavailableModelDoesNotStartCapture() async
    {
        let source = TestLiveTranscriptionSource()
        let coordinator = make(source: source, model: TestLiveCoachingModel(status: .otherUnavailable))
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .failed
        }
        #expect(source.startCount == 0)
    }

    @Test func generationFailureKeepsSessionActiveWithoutCue() async throws
    {
        let source = TestLiveTranscriptionSource()
        let coordinator = make(source: source, model: TestLiveCoachingModel(fails: true))
        coordinator.start(localeIdentifier: "en-US", profile: CoachingProfile(), style: .normal)
        await settle
        {
            coordinator.state == .listening
        }
        source.receive?(try speech(final: true))
        await coordinator.tick()
        await settle
        {
            coordinator.modelFailureCount == 1
        }
        #expect(coordinator.state == .listening)
        #expect(coordinator.cue == nil)
        await coordinator.stop()
    }

    private func make(
        source: TestLiveTranscriptionSource, model: TestLiveCoachingModel = TestLiveCoachingModel()
    ) -> LiveSessionCoordinator
    {
        LiveSessionCoordinator(source: source, model: model, clock: {
            100
        }, automaticallyTicks: false)
    }

    private func speech(final: Bool) throws -> TranscriptEvent
    {
        try TranscriptEvent(
            channel: .meeting,
            startSeconds: 97,
            endSeconds: 99,
            text: "Which promotion criteria still need more evidence?",
            isFinal: final
        )
    }

    private func settle(_ condition: () -> Bool) async
    {
        for _ in 0 ..< 2000
        {
            if condition()
            {
                return
            }
            await Task.yield()
        }
        #expect(condition())
    }
}
