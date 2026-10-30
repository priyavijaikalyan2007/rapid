// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79ac0567-8144-4e51-84e6-000000000024
// Created: 2026
// COMPONENT: Live coaching quality controls
// PURPOSE: Preserve bounded useful context and explain silence without retaining meeting content.
// RELATES: LiveSessionCoordinator, LiveCoachingInput, CueArbiter
// FLOW: Current speech -> validated candidate -> reasoned arbitration -> transient diagnostics and cleanup.

import Foundation

/// A small lexical check complements recent-advice context. It is not a claim of semantic equivalence.
struct CueRepeatKey: Sendable
{
    let kind: CueKind
    private let words: Set<String>

    init(kind: CueKind, instruction: String)
    {
        self.kind = kind
        let stop: Set<String> = [
            "a", "an", "the", "to", "of", "on", "for", "and", "or", "your", "you",
            "which", "what", "who", "how", "when", "where", "why", "ask", "clarify",
            "state", "explain", "give", "say", "before", "after", "next", "please",
            "could", "can", "would", "about", "that", "this"
        ]
        words = Set(instruction.lowercased().split
        {
            !$0.isLetter && !$0.isNumber
        }
        .map(String.init).filter
        {
            !stop.contains($0)
        })
    }

    func matches(_ other: CueRepeatKey) -> Bool
    {
        guard kind == other.kind
        else
        {
            return false
        }
        if kind == .pause || kind == .rephrase
        {
            return true
        }
        guard !words.isEmpty, !other.words.isEmpty
        else
        {
            return words == other.words
        }
        let shared = words.intersection(other.words).count
        return Double(shared) / Double(min(words.count, other.words.count)) >= 0.75
    }
}
