// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f1c59e5e-c7e4-4fe0-891d-128c0dcb78b4
// Created: 2026
// COMPONENT: Local benchmark response boundary
// PURPOSE: Replay typed invented replies through independent Core validation and actual sparse arbitration.
// RELATES: LocalBenchmarkFixtures, CueProposal, CueArbiter
// FLOW: Bounded benchmark artifact -> closed action -> validated instruction -> displayed cue or failed quality check.

import ComposureCore
import Foundation
import FoundationModels

@Generable
struct LocalBenchmarkReply: Codable, Sendable
{
    @Generable
    enum Action: String, Codable, Sendable
    {
        case noAction, clarify, askFirst, decisionFocus, dontGuess, pause, rephrase
    }

    var action: Action
    @Guide(description: "Confidence that the current action helps now", .range(0 ... 1))
    var confidence: Double
    @Guide(
        description: "An empty string for noAction. Otherwise one forward-looking English imperative of 3 to 18 words."
    )
    var instruction: String

    struct Report: Codable
    {
        let version: Int
        let dataClass: String
        let cases: [Record]
    }

    struct Record: Codable
    {
        let id: String
        let group: String
        let offset: Double
        let status: String
        let elapsedSeconds: Double
        let reply: LocalBenchmarkReply?

        func check(_ fixture: LocalBenchmarkFixtures.Case, arbiter: CueArbiter) async throws -> Bool
        {
            guard id == fixture.id, group == fixture.group, offset == fixture.offset, status == "ok",
                  elapsedSeconds.isFinite, elapsedSeconds >= 0, elapsedSeconds <= 6, let reply,
                  reply.confidence.isFinite, (0 ... 1).contains(reply.confidence)
            else
            {
                return false
            }
            if reply.action == .noAction
            {
                return fixture.expected.isEmpty && reply.instruction.isEmpty
            }
            guard let kind = CueKind(rawValue: reply.action.rawValue),
                  let proposal = try? CueProposal(
                      kind: kind,
                      instruction: reply.instruction,
                      confidence: reply.confidence,
                      evidenceID: UUID()
                  )
            else
            {
                return false
            }
            let delivered = 100 + offset + elapsedSeconds
            _ = await arbiter.current(at: delivered)
            let shown = await arbiter.consider(proposal, evidenceEnd: 99 + offset, now: delivered)
            return fixture.expected.contains(kind.rawValue) && shown != nil
        }
    }
}
