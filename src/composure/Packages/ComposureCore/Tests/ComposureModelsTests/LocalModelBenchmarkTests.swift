// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: cf7a6920-7879-4fa6-a12b-a03ffad3684c
// Created: 2026
// COMPONENT: Local model comparison harness
// PURPOSE: Export invented cases and score local replies through actual Core validation and arbitration.
// RELATES: LocalBenchmarkFixtures, LocalBenchmarkReply, composure_model_benchmark.py
// FLOW: Explicit opt-in -> invented requests -> local model -> independent Core replay.

import ComposureCore
import Foundation
import FoundationModels
import Testing
@testable import ComposureModels

struct LocalModelBenchmarkTests
{
    @Test func currentEvidenceFollowsTheBackgroundInThePrompt() throws
    {
        let input = LocalBenchmarkFixtures.Input(
            currentSpeech: "CURRENT_MARKER",
            previousSpeech: ["OLDER_MARKER"],
            objective: "GOAL_MARKER",
            style: "Normal",
            priorities: []
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let text = String(decoding: try encoder.encode(input), as: UTF8.self)
        let older = try #require(text.range(of: "OLDER_MARKER"))
        let current = try #require(text.range(of: "CURRENT_MARKER"))
        #expect(older.lowerBound < current.lowerBound)
    }

    @Test(
        .enabled(if: ProcessInfo.processInfo.environment["COMPOSURE_BENCHMARK_MODE"] == "apple-development"),
        .timeLimit(.minutes(5))
    )
    func compareAppleWithTheSharedPolicy() async throws
    {
        let model = AppleFoundationCoachingModel()
        try #require(await model.readiness() == .available)
        let document = LocalBenchmarkFixtures.document()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let warmup = LocalBenchmarkFixtures.Case(
            id: "warmup", group: "warmup", offset: 0,
            input: .init(
                currentSpeech: "The review time is confirmed. Thank you.",
                previousSpeech: [],
                objective: "",
                style: "Normal",
                priorities: []
            ), expected: []
        )
        _ = await appleReply(warmup, policy: document.policy, encoder: encoder)
        var records: [LocalBenchmarkReply.Record] = []
        for fixture in document.cases
        {
            try Task.checkCancellation()
            records.append(await appleReply(fixture, policy: document.policy, encoder: encoder))
        }
        let report = LocalBenchmarkReply.Report(version: 1, dataClass: "invented", cases: records)
        let path = try #require(ProcessInfo.processInfo.environment["COMPOSURE_BENCHMARK_OUTPUT_PATH"])
        try encoder.encode(report).write(to: URL(fileURLWithPath: path), options: .atomic)
        print("Recorded \(records.count) shared-policy Apple benchmark cases.")
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["COMPOSURE_BENCHMARK_MODE"] == "export-development"))
    func exportInventedDevelopmentFixtures() throws
    {
        let document = LocalBenchmarkFixtures.document()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let path = try #require(ProcessInfo.processInfo.environment["COMPOSURE_BENCHMARK_EXPORT_PATH"])
        try encoder.encode(document).write(to: URL(fileURLWithPath: path), options: .atomic)
        print("Exported \(document.cases.count) invented benchmark cases.")
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["COMPOSURE_BENCHMARK_REPLAY"] != nil))
    func replayLocalRepliesThroughCore() async throws
    {
        let path = try #require(ProcessInfo.processInfo.environment["COMPOSURE_BENCHMARK_REPLAY"])
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        try #require(data.count <= 262_144)
        let report = try JSONDecoder().decode(LocalBenchmarkReply.Report.self, from: data)
        try #require(report.version == 1 && report.dataClass == "invented")
        let fixtures = LocalBenchmarkFixtures.document().cases
        try #require(Set(report.cases.map(\.id)) == Set(fixtures.map(\.id)))
        try #require(report.cases.count == fixtures.count)
        var arbiters: [String: CueArbiter] = [:]
        for fixture in fixtures
        {
            let reply = try #require(report.cases.first
            {
                $0.id == fixture.id
            })
            let arbiter = arbiters[fixture.group] ?? CueArbiter(profile: CoachingProfile())
            arbiters[fixture.group] = arbiter
            let result = try await reply.check(fixture, arbiter: arbiter)
            print("COMPOSURE_BENCHMARK_CHECK: \(fixture.id) match=\(result)")
            #expect(result, "Invented case: \(fixture.id)")
        }
    }

    private func appleReply(
        _ fixture: LocalBenchmarkFixtures.Case, policy: String, encoder: JSONEncoder
    ) async -> LocalBenchmarkReply.Record
    {
        let started = ContinuousClock.now
        var reply: LocalBenchmarkReply?
        do
        {
            let prompt = String(decoding: try encoder.encode(fixture.input), as: UTF8.self)
            reply = try await appleGeneration(policy: policy, prompt: prompt)
        }
        catch
        {
            // The benchmark contains invented data. Provider error text is still excluded.
        }
        let duration = started.duration(to: .now).components
        let elapsed = Double(duration.seconds) + Double(duration.attoseconds) / 1e18
        let status = elapsed > 6 ? "deadlineExceeded" : (reply == nil ? "generationFailed" : "ok")
        return .init(
            id: fixture.id,
            group: fixture.group,
            offset: fixture.offset,
            status: status,
            elapsedSeconds: elapsed,
            reply: reply
        )
    }

    private func appleGeneration(policy: String, prompt: String) async throws -> LocalBenchmarkReply
    {
        try await withThrowingTaskGroup(of: LocalBenchmarkReply.self)
        { group in
            group.addTask
            {
                let session = LanguageModelSession(instructions: policy)
                return try await session.respond(
                    to: prompt,
                    generating: LocalBenchmarkReply.self,
                    options: .init(temperature: 0, maximumResponseTokens: 192)
                ).content
            }
            group.addTask
            {
                try await Task.sleep(for: .seconds(6))
                throw CancellationError()
            }
            defer { group.cancelAll() }
            guard let reply = try await group.next()
            else
            {
                throw CancellationError()
            }
            return reply
        }
    }
}
