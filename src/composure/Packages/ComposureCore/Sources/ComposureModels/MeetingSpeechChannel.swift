// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000081
// Created: 2026
// COMPONENT: Mac live audio capture
// PURPOSE: Stream separate bounded audio into ephemeral on-device speech with explicit cleanup.
// RELATES: LiveSessionCoordinator, MacMeetingAudioSource, MeetingSpeechChannel
// FLOW: Explicit Start and picker -> transient audio -> two analyzers -> confirmed Stop.

#if os(macOS)
import AVFoundation
import ComposureCore
import CoreMedia
import Speech

/// One analyzer owns one bounded audio input sequence and one result consumer.
@MainActor
final class MeetingSpeechChannel
{
    let transcriber: SpeechTranscriber
    let analyzer: SpeechAnalyzer
    let input: AsyncStream<AnalyzerInput>.Continuation
    private let sequence: AsyncStream<AnalyzerInput>
    private var analysis: Task<Void, Never>?
    private var results: Task<Void, Never>?

    init(locale: Locale)
    {
        transcriber = SpeechTranscriber(locale: locale, preset: .timeIndexedProgressiveTranscription)
        analyzer = SpeechAnalyzer(modules: [transcriber])
        let pair = AsyncStream<AnalyzerInput>.makeStream(bufferingPolicy: .bufferingOldest(8))
        input = pair.continuation
        sequence = pair.stream
    }

    func prepare(format: AVAudioFormat) async throws
    {
        try await analyzer.prepareToAnalyze(in: format)
        try Task.checkCancellation()
    }

    func start(
        channel: ComposureCore.SpeechChannel, origin: CMTime,
        receive: @escaping @MainActor @Sendable (TranscriptEvent) -> Void,
        failure: @escaping @MainActor @Sendable (LiveSessionError) -> Void
    )
    {
        let analyzer = analyzer
        let sequence = sequence
        analysis = Task
        {
            do
            {
                try await analyzer.start(inputSequence: sequence)
            }
            catch
            {
                if !Task.isCancelled
                {
                    failure(.speechUnavailable)
                }
            }
        }
        let transcriber = transcriber
        results = Task
        {
            do
            {
                for try await result in transcriber.results
                {
                    try Task.checkCancellation()
                    let text = String(result.text.characters)
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    {
                        continue
                    }
                    receive(try MeetingSpeechTiming.event(
                        range: result.range,
                        origin: origin,
                        channel: channel,
                        text: text,
                        isFinal: result.isFinal
                    ))
                }
                if !Task.isCancelled
                {
                    failure(.speechUnavailable)
                }
            }
            catch
            {
                if !Task.isCancelled
                {
                    failure(.speechUnavailable)
                }
            }
        }
    }

    func stop() async
    {
        input.finish()
        analysis?.cancel()
        results?.cancel()
        await analyzer.cancelAndFinishNow()
        await analysis?.value
        await results?.value
        analysis = nil
        results = nil
    }
}
#endif
