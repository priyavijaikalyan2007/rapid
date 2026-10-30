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

/// Serializes timing decisions. Rejected candidates are discarded rather than queued.
public actor CueArbiter
{
    private let policy: CuePolicy
    private var visible: CoachCue?
    private var lastByKind: [CueKind: Double] = [:]
    private var recent: [Double] = []

    public init(profile: CoachingProfile)
    {
        policy = CuePolicy(profile: profile)
    }

    public func consider(_ proposal: CueProposal, evidenceEnd: Double, now: Double) -> CoachCue?
    {
        _ = current(at: now)
        recent.removeAll
        {
            now - $0 >= 600
        }
        guard now.isFinite, evidenceEnd.isFinite, evidenceEnd <= now + 0.5,
              now - evidenceEnd <= CuePolicy.maximumEvidenceAge, visible == nil,
              recent.count < policy.maximumInTenMinutes,
              recent.last.map({
                  now - $0 >= policy.cooldownSeconds
              }) ?? true,
              lastByKind[proposal.kind].map({
                  now - $0 >= CuePolicy.repeatSeconds
              }) ?? true
        else
        {
            return nil
        }
        let cue = CoachCue(
            id: UUID(),
            kind: proposal.kind,
            priority: .normal,
            instruction: proposal.instruction,
            createdAt: now,
            expiresAt: now + CuePolicy.displaySeconds
        )
        visible = cue
        recent.append(now)
        lastByKind[proposal.kind] = now
        return cue
    }

    public func current(at now: Double) -> CoachCue?
    {
        if let visible, !now.isFinite || now >= visible.expiresAt
        {
            self.visible = nil
        }
        return visible
    }

    public func clear()
    {
        visible = nil
        recent = []
        lastByKind = [:]
    }
}
