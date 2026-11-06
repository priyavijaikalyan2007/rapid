// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: ba8bd0a9-587d-46e7-802f-c268f8afcd99
// Created: 2026
// COMPONENT: Automatic detector experiment replay
// PURPOSE: Score invented timed observations through actual Core and the pre-registered restricted-scope gate.
// RELATES: CueArbiter, composure_detector_policy.py, composure-automatic-detector.fixtures.json
// FLOW: Explicit fixture and report paths -> actual cue decisions -> inspectable outcomes and development gate.

import ComposureCore
import Foundation
import Testing

struct AutomaticDetectorReplayTests
{
    @Test func silenceCannotSatisfyTheUsefulCueGate()
    {
        #expect(!Self.meetsGate(valid: 32, wrong: 0, useful: 0))
    }

    @Test func oneWrongDisplayedCueFailsTheGate()
    {
        #expect(!Self.meetsGate(valid: 32, wrong: 1, useful: 12))
    }

    @Test func tenUsefulCuesWithNoWrongCuePassTheGate()
    {
        #expect(Self.meetsGate(valid: 32, wrong: 0, useful: 10))
    }

    @Test func invalidOutputCannotCountAsCorrectSilence()
    {
        #expect(!Self.meetsGate(valid: 31, wrong: 0, useful: 12))
    }

    /// The new gate is limited to the frozen 32-turn development trial, not product adoption.
    static func meetsGate(valid: Int, wrong: Int, useful: Int) -> Bool
    {
        valid == 32 && wrong == 0 && useful >= 10
    }

    private struct Fixture: Decodable
    {
        let id: String
        let group: String
        let offset: Double
        let expected: [String]
    }

    private struct Fixtures: Decodable
    {
        let version: Int
        let dataClass: String
        let cases: [Fixture]
    }

    private struct Report: Decodable
    {
        let version: Int
        let dataClass: String
        let mode: String
        let cases: [LocalBenchmarkReply.Record]
    }

    private struct Outcome: Codable
    {
        let id: String
        let valid: Bool
        let required: Bool
        let displayed: String?
        let useful: Bool
        let wrong: Bool
        let matched: Bool
        let disposition: String
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["COMPOSURE_DETECTOR_REPORT"] != nil))
    func replayAutomaticDetectorConversationTrial() async throws
    {
        let fixtures = try loadFixtures()
        let report: Report = try read("COMPOSURE_DETECTOR_REPORT")
        try #require(report.version == 1 && report.dataClass == "invented" && report.mode == "constrained")
        try #require(report.cases.count == fixtures.count)
        try #require(Set(report.cases.map(\.id)) == Set(fixtures.map(\.id)))
        var arbiters: [String: CueArbiter] = [:]
        var outcomes: [Outcome] = []
        for fixture in fixtures
        {
            let record = try #require(report.cases.first
            {
                $0.id == fixture.id
            })
            let arbiter = arbiters[fixture.group] ?? CueArbiter(profile: CoachingProfile())
            arbiters[fixture.group] = arbiter
            outcomes.append(await evaluate(fixture, record: record, arbiter: arbiter))
        }
        try write(outcomes)
        let valid = outcomes.filter(\.valid).count
        let wrong = outcomes.filter(\.wrong).count
        let useful = outcomes.filter(\.useful).count
        print("COMPOSURE_DETECTOR_GATE: valid=\(valid) wrong=\(wrong) useful=\(useful)")
        #expect(Self.meetsGate(valid: valid, wrong: wrong, useful: useful))
    }

    /// Fixture input text is deliberately not decoded here. Python validates evidence; this layer tests real delivery.
    private func loadFixtures() throws -> [Fixture]
    {
        let document: Fixtures = try read("COMPOSURE_DETECTOR_FIXTURES")
        try #require(document.version == 1 && document.dataClass == "invented")
        try #require(document.cases.count == 32 && Set(document.cases.map(\.id)).count == 32)
        try #require(document.cases.filter
        {
            !$0.expected.isEmpty
        }.count == 12)
        var previous: [String: Double] = [:]
        let supported = Set(["clarify", "decisionFocus", "dontGuess"])
        for fixture in document.cases
        {
            try #require(!fixture.id.isEmpty && fixture.id.count <= 96)
            try #require(!fixture.group.isEmpty && fixture.group.count <= 96)
            try #require(fixture.offset.isFinite && (0 ... 600).contains(fixture.offset))
            try #require(fixture.offset >= previous[fixture.group, default: 0])
            try #require(Set(fixture.expected).isSubset(of: supported))
            previous[fixture.group] = fixture.offset
        }
        return document.cases
    }

    private func read<Value: Decodable>(_ variable: String) throws -> Value
    {
        let path = try #require(ProcessInfo.processInfo.environment[variable])
        let url = URL(fileURLWithPath: path)
        let size = try #require(url.resourceValues(forKeys: [.fileSizeKey]).fileSize)
        try #require(size <= 262_144)
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        try #require(data.count <= 262_144)
        return try JSONDecoder().decode(Value.self, from: data)
    }

    private func evaluate(_ fixture: Fixture, record: LocalBenchmarkReply.Record, arbiter: CueArbiter) async -> Outcome
    {
        guard record.id == fixture.id, record.group == fixture.group, record.offset == fixture.offset,
              record.status == "ok", record.elapsedSeconds.isFinite, (0 ... 6).contains(record.elapsedSeconds),
              let reply = record.reply, reply.confidence.isFinite, (0 ... 1).contains(reply.confidence)
        else
        {
            return outcome(fixture, valid: false, displayed: nil, matched: false, disposition: "invalidOutput")
        }
        _ = await arbiter.current(at: 100 + fixture.offset + record.elapsedSeconds)
        if reply.action == .noAction
        {
            return silenceOutcome(fixture, reply: reply)
        }
        guard let proposal = proposal(reply)
        else
        {
            return outcome(fixture, valid: true, displayed: nil, matched: false, disposition: "proposalRejected")
        }
        return await deliver(fixture, proposal: proposal, elapsed: record.elapsedSeconds, arbiter: arbiter)
    }

    private func silenceOutcome(_ fixture: Fixture, reply: LocalBenchmarkReply) -> Outcome
    {
        outcome(
            fixture,
            valid: reply.instruction.isEmpty,
            displayed: nil,
            matched: fixture.expected.isEmpty && reply.instruction.isEmpty,
            disposition: "noAction"
        )
    }

    private func proposal(_ reply: LocalBenchmarkReply) -> CueProposal?
    {
        guard let kind = CueKind(rawValue: reply.action.rawValue)
        else
        {
            return nil
        }
        return try? CueProposal(
            kind: kind,
            instruction: reply.instruction,
            confidence: reply.confidence,
            evidenceID: UUID()
        )
    }

    private func deliver(
        _ fixture: Fixture, proposal: CueProposal, elapsed: Double, arbiter: CueArbiter
    ) async -> Outcome
    {
        let decision = await arbiter.decide(
            proposal,
            evidenceEnd: 99 + fixture.offset,
            now: 100 + fixture.offset + elapsed
        )
        let shown = decision.cue?.kind.rawValue
        return outcome(
            fixture,
            valid: true,
            displayed: shown,
            matched: shown.map(fixture.expected.contains) ?? false,
            disposition: decision.suppressionReason?.rawValue ?? "displayed"
        )
    }

    private func outcome(
        _ fixture: Fixture,
        valid: Bool,
        displayed: String?,
        matched: Bool,
        disposition: String
    ) -> Outcome
    {
        let useful = displayed.map(fixture.expected.contains) ?? false
        return Outcome(
            id: fixture.id,
            valid: valid,
            required: !fixture.expected.isEmpty,
            displayed: displayed,
            useful: useful,
            wrong: displayed != nil && !useful,
            matched: matched,
            disposition: disposition
        )
    }

    private func write(_ outcomes: [Outcome]) throws
    {
        let path = try #require(ProcessInfo.processInfo.environment["COMPOSURE_DETECTOR_REPLAY_OUTPUT"])
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        try encoder.encode(outcomes).write(to: URL(fileURLWithPath: path), options: .withoutOverwriting)
        for result in outcomes
        {
            print(
                """
                COMPOSURE_DETECTOR_CHECK: \(result.id) matched=\(result.matched) \
                displayed=\(result.displayed ?? "none")
                """
            )
        }
    }
}
