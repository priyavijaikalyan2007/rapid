// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000010
// Created: 2026
// COMPONENT: Transient live coaching
// PURPOSE: Bound private speech context and validate sparse actionable cues.
// RELATES: LiveSessionCoordinator, CueArbiter, ConversationBuffer
// FLOW: Explicit listening -> bounded context -> validated temporary cue -> Stop and clear.

import Foundation

/// Serializes display decisions. Bounded recent advice supports repeat control without a historical UI queue.
public actor CueArbiter
{
    private struct Record: Sendable
    {
        let cue: CoachCue
        let key: CueRepeatKey
    }

    private let policy: CuePolicy
    private var visible: CoachCue?
    private var recent: [Record] = []
    private var recentTimes: [Double] = []
    private var lastHighPriority: Double?

    public init(profile: CoachingProfile)
    {
        policy = CuePolicy(profile: profile)
    }

    public func consider(_ proposal: CueProposal, evidenceEnd: Double, now: Double) -> CoachCue?
    {
        decide(proposal, evidenceEnd: evidenceEnd, now: now).cue
    }

    public func decide(_ proposal: CueProposal, evidenceEnd: Double, now: Double) -> CueDecision
    {
        guard now.isFinite, evidenceEnd.isFinite
        else
        {
            return .suppressed(.invalidTiming)
        }
        _ = current(at: now)
        if evidenceEnd > now + 0.5
        {
            return .suppressed(.invalidTiming)
        }
        if now - evidenceEnd > CuePolicy.maximumEvidenceAge
        {
            return .suppressed(.staleEvidence)
        }
        if let reason = presentationFailure(proposal, now: now)
        {
            return .suppressed(reason)
        }
        let key = CueRepeatKey(kind: proposal.kind, instruction: proposal.instruction)
        if recent.contains(where: {
            now - $0.cue.createdAt < CuePolicy.repeatSeconds && key.matches($0.key)
        })
        {
            return .suppressed(.duplicate)
        }
        return accept(proposal, key: key, now: now)
    }

    private func presentationFailure(_ proposal: CueProposal, now: Double) -> CueSuppressionReason?
    {
        if let visible, proposal.priority.rawValue <= visible.priority.rawValue
        {
            return .visibleCue
        }
        if recentTimes.count >= policy.maximumInTenMinutes
        {
            return .rateLimit
        }
        let high = proposal.priority == .high
        let previous = high ? lastHighPriority : recentTimes.last
        let cooldown = high ? CuePolicy.highPriorityCooldownSeconds : policy.cooldownSeconds
        if let previous, now - previous < cooldown
        {
            return .cooldown
        }
        return nil
    }

    private func accept(_ proposal: CueProposal, key: CueRepeatKey, now: Double) -> CueDecision
    {
        let cue = CoachCue(
            id: UUID(),
            kind: proposal.kind,
            priority: proposal.priority,
            instruction: proposal.instruction,
            createdAt: now,
            expiresAt: now + CuePolicy.displaySeconds
        )
        visible = cue
        recent.append(Record(cue: cue, key: key))
        recentTimes.append(now)
        if cue.priority == .high
        {
            lastHighPriority = now
        }
        return .displayed(cue)
    }

    public func recentContext(at now: Double) -> [RecentCueContext]
    {
        recent.filter
        {
            now.isFinite && now >= $0.cue.createdAt && now - $0.cue.createdAt <= 120
        }
        .suffix(4).map
        {
            RecentCueContext(cue: $0.cue)
        }
    }

    public func current(at now: Double) -> CoachCue?
    {
        pruneHistory(at: now)
        if let visible, !now.isFinite || now >= visible.expiresAt
        {
            self.visible = nil
        }
        return visible
    }

    private func pruneHistory(at now: Double)
    {
        recent.removeAll
        {
            !now.isFinite || now - $0.cue.createdAt > 120
        }
        recentTimes.removeAll
        {
            !now.isFinite || now - $0 >= 600
        }
    }

    public func clear()
    {
        visible = nil
        recent = []
        recentTimes = []
        lastHighPriority = nil
    }
}
