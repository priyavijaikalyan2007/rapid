// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9eb635c6-5153-46c1-acc4-d7ce7f66a4e4
// Created: 2026
// COMPONENT: Preparation regression tests
// PURPOSE: Verify bounded, transient coaching without real conversation content.
// RELATES: PreparationService, MeetingPreparation
// FLOW: Synthetic input -> preparation contract -> bounded result or controlled failure.

import Testing
@testable import ComposureCore

struct PreparationValidationTests
{
    @Test func emptyTopicIsRejected() throws
    {
        #expect(throws: PreparationError.topicRequired) { try MeetingPreparationInput(topic: "  ") }
    }

    @Test func topicBytesAreBounded() throws
    {
        #expect(throws: PreparationError.inputTooLong)
        {
            try MeetingPreparationInput(topic: String(repeating: "😀", count: 513))
        }
    }

    @Test func optionalInputIsBounded() throws
    {
        #expect(throws: PreparationError.inputTooLong)
        {
            try MeetingPreparationInput(topic: "Synthetic discussion", outcome: String(repeating: "a", count: 1025))
        }
    }

    @Test func normalInputRetainsMeaningfulWhitespace() throws
    {
        let input = try MeetingPreparationInput(topic: "First line\nSecond line")
        #expect(input.topic == "First line\nSecond line")
    }

    @Test func outputRejectsEmptyRequiredSection() throws
    {
        #expect(throws: PreparationError.invalidOutput)
        {
            try MeetingPreparation(
                objective: "",
                watchFor: ["Pause."],
                questionsToAsk: ["What matters?"],
                ifChallenged: "Ask first.",
                keepInMind: ["Be concise."]
            )
        }
    }

    @Test func outputRejectsExcessiveListCount() throws
    {
        #expect(throws: PreparationError.invalidOutput)
        {
            try MeetingPreparation(
                objective: "Clarify.",
                watchFor: Array(repeating: "Pause.", count: 4),
                questionsToAsk: ["What matters?"],
                ifChallenged: "Ask first.",
                keepInMind: ["Be concise."]
            )
        }
    }

    @Test func outputRejectsLongItems() throws
    {
        #expect(throws: PreparationError.invalidOutput)
        {
            try MeetingPreparation(
                objective: String(repeating: "a", count: 281),
                watchFor: ["Pause."],
                questionsToAsk: ["What matters?"],
                ifChallenged: "Ask first.",
                keepInMind: ["Be concise."]
            )
        }
    }

    @Test func controlCharactersAreRejected() throws
    {
        #expect(throws: PreparationError.invalidInput) { try MeetingPreparationInput(topic: "Synthetic\u{0}topic") }
    }
}
