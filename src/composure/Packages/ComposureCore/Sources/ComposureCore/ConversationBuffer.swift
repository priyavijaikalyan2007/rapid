// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000005
// Created: 2026
// COMPONENT: Transient live coaching
// PURPOSE: Bound private speech context and validate sparse actionable cues.
// RELATES: LiveSessionCoordinator, CueArbiter, ConversationBuffer
// FLOW: Explicit listening -> bounded context -> validated temporary cue -> Stop and clear.

/// Owns a bounded rolling context. There is deliberately no serialization or persistence API.
public struct ConversationBuffer: Sendable
{
    public private(set) var events: [TranscriptEvent] = []
    public init()
    {
    }

    /// Replace overlapping partials on the same source. A late partial cannot alter finalized speech.
    public mutating func insert(_ event: TranscriptEvent, now: Double)
    {
        prune(now: now)
        guard now.isFinite, event.endSeconds > now - 120, event.endSeconds <= now + 0.5
        else
        {
            return
        }
        let revisions = events.filter
        {
            Self.overlaps($0, event)
        }
        guard !revisions.contains(where: {
            $0.isFinal
        }) else
        {
            return
        }
        let revised = revisions.first.map
        {
            event.replacingIdentity($0.id)
        } ?? event
        events.removeAll
        {
            Self.overlaps($0, event)
        }
        events.append(revised)
        events.sort
        {
            $0.startSeconds < $1.startSeconds
        }
        enforceLimits()
    }

    public mutating func prune(now: Double)
    {
        guard now.isFinite
        else
        {
            clear()
            return
        }
        events.removeAll
        {
            $0.endSeconds <= now - 120
        }
    }

    public mutating func clear()
    {
        events.removeAll(keepingCapacity: false)
    }

    private static func overlaps(_ first: TranscriptEvent, _ second: TranscriptEvent) -> Bool
    {
        first.channel == second.channel &&
            (first.id == second.id ||
                (first.startSeconds < second.endSeconds && second.startSeconds < first.endSeconds))
    }

    private mutating func enforceLimits()
    {
        while events.count > 128 || events.reduce(0, {
            $0 + $1.text.utf8.count
        }) > 32_768
        {
            events.removeFirst()
        }
    }
}
