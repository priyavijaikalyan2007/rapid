// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000062
// Created: 2026
// COMPONENT: Native live coaching adapter
// PURPOSE: Translate native speech and model results into bounded validated transient contracts.
// RELATES: MacMeetingAudioSource, LiveSessionCoordinator, AppleFoundationCoachingModel
// FLOW: Explicit listening -> native on-device processing -> validated event or brief cue.

#if os(macOS)
import ComposureCore
import CoreMedia

/// Analyzer ranges refer to the same relative timeline used by both channel inputs.
enum MeetingSpeechTiming
{
    static func event(
        range: CMTimeRange, origin: CMTime, channel: ComposureCore.SpeechChannel, text: String, isFinal: Bool
    ) throws -> TranscriptEvent
    {
        guard range.isValid, range.start.isNumeric, range.duration.isNumeric, origin.isNumeric,
              range.start.seconds >= 0, range.duration.seconds > 0
        else
        {
            throw LiveSessionError.invalidSpeech
        }
        return try TranscriptEvent(
            channel: channel, startSeconds: CMTimeAdd(origin, range.start).seconds,
            endSeconds: CMTimeAdd(origin, range.end).seconds,
            text: text.split(whereSeparator: {
                $0.isWhitespace
            }).joined(separator: " "), isFinal: isFinal
        )
    }
}
#endif
