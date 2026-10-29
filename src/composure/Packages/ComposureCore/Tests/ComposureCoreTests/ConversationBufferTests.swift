// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4fd393f8-41c4-47e4-9cf6-be385ae5fa16
// Created: 2026
// COMPONENT: Live speech contracts
// PURPOSE: Test bounded transient speech and revisions with synthetic text only.
// RELATES: TranscriptEvent, ConversationBuffer
// FLOW: Synthetic revisions -> bounded ordered context -> clear on session end.

import Testing
@testable import ComposureCore

struct ConversationBufferTests
{
    @Test func partialRevisionAndFinalKeepOneIdentity() throws
    {
        var buffer = ConversationBuffer()
        let first = try event("A partial", start: 1, end: 2, final: false)
        buffer.insert(first, now: 3)
        buffer.insert(try event("A revised partial", start: 1, end: 2.5, final: false), now: 3)
        buffer.insert(try event("A final synthetic sentence.", start: 1, end: 3), now: 3)
        #expect(buffer.events.count == 1)
        #expect(buffer.events.first?.id == first.id)
        #expect(buffer.events.first?.isFinal == true)
    }

    @Test func latePartialCannotReplaceFinal() throws
    {
        var buffer = ConversationBuffer()
        buffer.insert(try event("Final words remain.", start: 1, end: 3), now: 4)
        buffer.insert(try event("Stale partial", start: 1, end: 4, final: false), now: 4)
        #expect(buffer.events.map(\.text) == ["Final words remain."])
    }

    @Test func separateChannelsDoNotReplaceEachOther() throws
    {
        var buffer = ConversationBuffer()
        buffer.insert(try event("First channel.", start: 1, end: 3), now: 4)
        buffer.insert(try event("Second channel.", start: 1, end: 3, channel: .meeting), now: 4)
        #expect(buffer.events.count == 2)
    }

    @Test func lateFinalsAreSortedByAudioTime() throws
    {
        var buffer = ConversationBuffer()
        buffer.insert(try event("Later sentence.", start: 5, end: 6), now: 7)
        buffer.insert(try event("Earlier sentence.", start: 1, end: 2), now: 7)
        #expect(buffer.events.map(\.startSeconds) == [1, 5])
    }

    @Test func idlePruningRemovesExpiredSpeech() throws
    {
        var buffer = ConversationBuffer()
        buffer.insert(try event("Expired sentence.", start: 1, end: 2), now: 3)
        buffer.prune(now: 123)
        #expect(buffer.events.isEmpty)
    }

    @Test func futureAndAlreadyExpiredEventsAreIgnored() throws
    {
        var buffer = ConversationBuffer()
        buffer.insert(try event("Expired sentence.", start: 1, end: 2), now: 200)
        buffer.insert(try event("Future sentence.", start: 210, end: 211), now: 200)
        #expect(buffer.events.isEmpty)
    }

    @Test func countAndAggregateBytesStayBounded() throws
    {
        var buffer = ConversationBuffer()
        for index in 0 ..< 500
        {
            let start = Double(index) / 10
            buffer.insert(try event(String(repeating: "s", count: 2048), start: start, end: start + 0.05), now: 51)
        }
        #expect(buffer.events.count <= 128)
        #expect(buffer.events.reduce(0)
        {
            $0 + $1.text.utf8.count
        } <= 32_768)
    }

    @Test func textAndAudioTimeAreValidated() throws
    {
        #expect(throws: LiveSessionError.invalidSpeech)
        {
            try event(String(repeating: "x", count: 2049), start: 1, end: 2)
        }
        #expect(throws: LiveSessionError.invalidSpeech) { try event("Invalid time.", start: .nan, end: 2) }
        #expect(throws: LiveSessionError.invalidSpeech) { try event("Invalid time.", start: 3, end: 2) }
        #expect(throws: LiveSessionError.invalidSpeech) { try event("Invalid\u{0}text.", start: 1, end: 2) }
    }

    @Test func clearReleasesAllOwnedSpeech() throws
    {
        var buffer = ConversationBuffer()
        buffer.insert(try event("Temporary synthetic sentence.", start: 1, end: 2), now: 3)
        buffer.clear()
        #expect(buffer.events.isEmpty)
    }

    private func event(
        _ text: String, start: Double, end: Double, final: Bool = true, channel: SpeechChannel = .microphone
    ) throws -> TranscriptEvent
    {
        try TranscriptEvent(channel: channel, startSeconds: start, endSeconds: end, text: text, isFinal: final)
    }
}
