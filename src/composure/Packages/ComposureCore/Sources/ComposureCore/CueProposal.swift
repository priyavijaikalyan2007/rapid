// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000007
// Created: 2026
// COMPONENT: Transient live coaching
// PURPOSE: Bound private speech context and validate sparse actionable cues.
// RELATES: LiveSessionCoordinator, CueArbiter, ConversationBuffer
// FLOW: Explicit listening -> bounded context -> validated temporary cue -> Stop and clear.

import Foundation

/// Independently validates generated text before it can reach an arbiter or native view.
public struct CueProposal: Sendable
{
    public let kind: CueKind
    public let instruction: String
    public let confidence: Double
    public let evidenceID: UUID

    public init(kind: CueKind, instruction: String, confidence: Double, evidenceID: UUID) throws
    {
        let text = instruction.trimmingCharacters(in: .whitespaces)
        let prohibited = [
            "calm down",
            "relax",
            "emotional",
            "angry",
            "overreact",
            "dishonest",
            "incompetent",
            "mental state",
            "http",
            "www.",
            "://"
        ]
        guard confidence.isFinite, confidence >= 0.8, confidence <= 1,
              !text.isEmpty, text.utf8.count <= 160,
              text.split(whereSeparator: {
                  $0.isWhitespace
              }).count <= 18,
              !text.unicodeScalars.contains(where: {
                  CharacterSet.controlCharacters.contains($0)
              }),
              !prohibited.contains(where: {
                  text.localizedCaseInsensitiveContains($0)
              })
        else
        {
            throw LiveSessionError.invalidCue
        }
        self.kind = kind
        self.instruction = text
        self.confidence = confidence
        self.evidenceID = evidenceID
    }
}
