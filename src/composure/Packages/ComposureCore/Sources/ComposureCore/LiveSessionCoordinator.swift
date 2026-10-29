// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000035
// Created: 2026
// COMPONENT: Live session coordination
// PURPOSE: Keep capture and coaching bounded, explicit, and transient across native lifecycle changes.
// RELATES: LiveSessionCoordinator, LiveTranscriptionSource, LiveCoachingModel
// FLOW: Explicit Start -> bounded private processing -> sparse cue -> Stop and clear.

import Foundation
import Observation

/// Owns transient session state. Native views only issue explicit actions and render safe state.
@MainActor
@Observable
public final class LiveSessionCoordinator
{
    public var objective = ""
    public private(set) var state: LiveSessionState = .idle
    public private(set) var cue: CoachCue?
    public private(set) var error: LiveSessionError?
    public private(set) var modelFailureCount = 0
    public private(set) var isCoachingAvailable = true
    public var retainedEventCount: Int
    {
        buffer.events.count
    }

    public var canStart: Bool
    {
        (state == .idle || state == .failed) && captureStopped
    }

    public var canStop: Bool
    {
        state == .starting || state == .listening || !captureStopped
    }

    @ObservationIgnored private let source: any LiveTranscriptionSource
    @ObservationIgnored private let model: any LiveCoachingModel
    @ObservationIgnored private let clock: @MainActor @Sendable () -> Double
    @ObservationIgnored private let automaticallyTicks: Bool
    @ObservationIgnored private let logger: DiagnosticLogger
    @ObservationIgnored private var buffer = ConversationBuffer()
    @ObservationIgnored private var arbiter = CueArbiter(profile: CoachingProfile())
    @ObservationIgnored private var profile = CoachingProfile()
    @ObservationIgnored private var style: SessionStyle = .normal
    @ObservationIgnored private var sessionID: UUID?
    @ObservationIgnored private var startup: Task<Void, Never>?
    @ObservationIgnored private var timer: Task<Void, Never>?
    @ObservationIgnored private var generation: Task<Void, Never>?
    @ObservationIgnored private var captureStopped = true
    @ObservationIgnored private var lastOpportunity = -Double.infinity
    @ObservationIgnored private var lastEvidenceEnd = -Double.infinity

    public init(
        source: any LiveTranscriptionSource, model: any LiveCoachingModel,
        clock: @escaping @MainActor @Sendable () -> Double = {
            ProcessInfo.processInfo.systemUptime
        },
        automaticallyTicks: Bool = true, logger: DiagnosticLogger = DiagnosticLogger { _, _ in }
    )
    {
        self.source = source
        self.model = model
        self.clock = clock
        self.automaticallyTicks = automaticallyTicks
        self.logger = logger
    }

    public func start(localeIdentifier: String, profile: CoachingProfile, style: SessionStyle)
    {
        guard canStart
        else
        {
            return
        }
        guard (
            try? LiveCoachingInput(events: [], objective: objective, profile: profile, style: style, now: clock())
        ) !=
            nil
        else
        {
            error = .objectiveTooLong
            return
        }
        let id = UUID()
        sessionID = id
        self.profile = profile
        self.style = style
        arbiter = CueArbiter(profile: profile)
        error = nil
        modelFailureCount = 0
        isCoachingAvailable = true
        lastOpportunity = -Double.infinity
        lastEvidenceEnd = -Double.infinity
        state = .starting
        startup = Task
        {
            await begin(localeIdentifier: localeIdentifier, id: id)
        }
    }

    private func begin(localeIdentifier: String, id: UUID) async
    {
        do
        {
            guard await model.readiness() == .available
            else
            {
                throw LiveSessionError.modelUnavailable
            }
            try Task.checkCancellation()
            captureStopped = false
            try await source.start(localeIdentifier: localeIdentifier, receive: { [weak self] event in
                self?.receive(event, id: id)
            }, failure: { [weak self] error in
                Task
                {
                    await self?.end(error: error, expectedID: id)
                }
            })
            try Task.checkCancellation()
            guard sessionID == id
            else
            {
                return
            }
            startup = nil
            state = .listening
            logger.record(.sessionStarted)
            startTimer(id: id)
        }
        catch
        {
            guard sessionID == id
            else
            {
                return
            }
            startup = nil
            await end(error: error as? LiveSessionError ?? .captureFailed, expectedID: id)
        }
    }

    private func receive(_ event: TranscriptEvent, id: UUID)
    {
        guard sessionID == id, state == .starting || state == .listening
        else
        {
            return
        }
        buffer.insert(event, now: clock())
    }

    /// Also permits deterministic tests to advance expiry and pruning without a real timer.
    public func tick() async
    {
        guard let id = sessionID, state == .listening
        else
        {
            return
        }
        let now = clock()
        buffer.prune(now: now)
        let current = await arbiter.current(at: now)
        guard sessionID == id
        else
        {
            return
        }
        cue = current
        guard generation == nil, now - lastOpportunity >= 3,
              let input = try? LiveCoachingInput(
                  events: buffer.events,
                  objective: objective,
                  profile: profile,
                  style: style,
                  now: now
              ),
              let latest = input.events.max(by: {
                  $0.endSeconds < $1.endSeconds
              }),
              latest.endSeconds > lastEvidenceEnd,
              now - latest.endSeconds <= CuePolicy.maximumEvidenceAge
        else
        {
            return
        }
        lastOpportunity = now
        lastEvidenceEnd = latest.endSeconds
        let arbiter = arbiter
        generation = Task
        {
            await evaluate(input, arbiter: arbiter, id: id)
        }
    }

    private func evaluate(_ input: LiveCoachingInput, arbiter: CueArbiter, id: UUID) async
    {
        defer
        {
            if sessionID == id
            {
                generation = nil
            }
        }
        do
        {
            let proposal = try await request(input)
            try Task.checkCancellation()
            guard sessionID == id
            else
            {
                return
            }
            isCoachingAvailable = true
            guard let proposal,
                  let evidence = input.events.first(where: {
                      $0.id == proposal.evidenceID
                  })
            else
            {
                return
            }
            let accepted = await arbiter.consider(proposal, evidenceEnd: evidence.endSeconds, now: clock())
            guard sessionID == id
            else
            {
                return
            }
            if let accepted
            {
                cue = accepted
                logger.record(.liveCueDisplayed)
            }
        }
        catch
        {
            guard sessionID == id, !Task.isCancelled
            else
            {
                return
            }
            modelFailureCount = min(modelFailureCount + 1, 10_000)
            isCoachingAvailable = false
            logger.record(.liveModelFailed)
        }
    }

    private func request(_ input: LiveCoachingInput) async throws -> CueProposal?
    {
        let model = model
        return try await withThrowingTaskGroup(of: CueProposal?.self)
        { group in
            defer { group.cancelAll() }
            group.addTask
            {
                try await model.evaluate(input)
            }
            group.addTask
            {
                try await Task.sleep(for: .seconds(6))
                throw LiveSessionError.modelUnavailable
            }
            guard let result = try await group.next()
            else
            {
                throw CancellationError()
            }
            return result
        }
    }

    public func stop() async
    {
        await end(error: nil, expectedID: nil)
    }

    private func end(error failure: LiveSessionError?, expectedID: UUID?) async
    {
        guard expectedID == nil || expectedID == sessionID
        else
        {
            return
        }
        guard state != .stopping, state != .idle || !captureStopped
        else
        {
            return
        }
        sessionID = nil
        state = .stopping
        cue = nil
        objective = ""
        buffer.clear()
        let pending = cancelWork()
        source.cancelStart()
        await pending.0?.value
        let source = source
        let cleanup = Task
        { @MainActor in
            await source.stop()
        }
        captureStopped = await cleanup.value
        await pending.1?.value
        await arbiter.clear()
        error = captureStopped ? failure : .stopUnconfirmed
        state = error == nil ? .idle : .failed
        logger.record(.sessionStopped)
    }

    private func cancelWork() -> (Task<Void, Never>?, Task<Void, Never>?)
    {
        timer?.cancel()
        timer = nil
        let pending = (startup, generation)
        startup = nil
        generation = nil
        pending.0?.cancel()
        pending.1?.cancel()
        return pending
    }

    private func startTimer(id: UUID)
    {
        guard automaticallyTicks
        else
        {
            return
        }
        timer = Task
        { [weak self] in
            do
            {
                while !Task.isCancelled
                {
                    try await Task.sleep(for: .seconds(1))
                    guard let self, self.sessionID == id
                    else
                    {
                        return
                    }
                    await self.tick()
                }
            }
            catch
            {
            }
        }
    }
}
