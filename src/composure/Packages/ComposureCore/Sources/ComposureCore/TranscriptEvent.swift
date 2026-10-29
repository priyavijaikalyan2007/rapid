// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000004
// Created: 2026
// COMPONENT: Transient live coaching
// PURPOSE: Bound private speech context and validate sparse actionable cues.
// RELATES: LiveSessionCoordinator, CueArbiter, ConversationBuffer
// FLOW: Explicit listening -> bounded context -> validated temporary cue -> Stop and clear.

import Foundation

/// A transient result whose times use the same monotonic host clock as its owning session.
public struct TranscriptEvent: Identifiable, Sendable, Equatable
{
    public let id: UUID
    public let channel: SpeechChannel
    public let speaker: SpeakerRole
    public let startSeconds: Double
    public let endSeconds: Double
    public let text: String
    public let isFinal: Bool

    public init(
        id: UUID = UUID(), channel: SpeechChannel, speaker: SpeakerRole = .unknown,
        startSeconds: Double, endSeconds: Double, text: String, isFinal: Bool
    ) throws
    {
        guard startSeconds.isFinite, endSeconds.isFinite, startSeconds >= 0,
              endSeconds > startSeconds, endSeconds - startSeconds <= 120,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.utf8.count <= 2048,
              !text.unicodeScalars.contains(where: {
                  CharacterSet.controlCharacters.contains($0)
              })
        else
        {
            throw LiveSessionError.invalidSpeech
        }
        self.id = id
        self.channel = channel
        self.speaker = speaker
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
        self.text = text
        self.isFinal = isFinal
    }

    func replacingIdentity(_ id: UUID) -> TranscriptEvent
    {
        // All values already passed the constructor. Reconstructing cannot introduce invalid text or time.
        (try? TranscriptEvent(
            id: id,
            channel: channel,
            speaker: speaker,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            text: text,
            isFinal: isFinal
        )) ?? self
    }
}
