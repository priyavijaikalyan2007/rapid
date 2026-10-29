// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000032
// Created: 2026
// COMPONENT: Live session coordination
// PURPOSE: Keep capture and coaching bounded, explicit, and transient across native lifecycle changes.
// RELATES: LiveSessionCoordinator, LiveTranscriptionSource, LiveCoachingModel
// FLOW: Explicit Start -> bounded private processing -> sparse cue -> Stop and clear.

import Foundation

/// Smaller than the rolling buffer. Only recent finalized, meaningful speech enters a fresh request.
public struct LiveCoachingInput: Sendable
{
    public let events: [TranscriptEvent]
    public let objective: String
    public let profile: CoachingProfile
    public let style: SessionStyle

    public init(
        events: [TranscriptEvent], objective: String, profile: CoachingProfile, style: SessionStyle, now: Double
    ) throws
    {
        guard objective.utf8.count <= 512,
              !objective.unicodeScalars.contains(where: {
                  CharacterSet.controlCharacters.contains($0)
              })
        else
        {
            throw LiveSessionError.objectiveTooLong
        }
        var selected: [TranscriptEvent] = []
        var bytes = 0
        for event in events.sorted(by: {
            $0.endSeconds > $1.endSeconds
        })
        {
            guard event.isFinal, event.endSeconds > now - 30, event.endSeconds <= now + 0.5,
                  Self.isMeaningful(event.text), selected.count < 8,
                  bytes + event.text.utf8.count <= 4096
            else
            {
                continue
            }
            selected.append(event)
            bytes += event.text.utf8.count
        }
        self.events = selected.sorted
        {
            $0.startSeconds < $1.startSeconds
        }
        self.objective = objective.trimmingCharacters(in: .whitespaces)
        self.profile = profile
        self.style = style
    }

    private static func isMeaningful(_ text: String) -> Bool
    {
        let filler: Set<String> = ["um", "uh", "hmm", "ah", "okay", "ok", "yes", "no"]
        let words = text.lowercased().split
        {
            !$0.isLetter && !$0.isNumber
        }
        return words.filter
        {
            !filler.contains(String($0))
        }.count >= 3
    }
}
