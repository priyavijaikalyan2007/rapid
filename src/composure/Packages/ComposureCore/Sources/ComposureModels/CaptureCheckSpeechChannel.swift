// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: afd9beba-ad3a-45a8-a245-6fe0878b7039
// Created: 2026
// COMPONENT: Debug Mac capture experiment
// PURPOSE: Check separate transient audio streams with bounded processing and no recording output.
// RELATES: MacCaptureCheck, CaptureCheckMetrics
// FLOW: Explicit capture start -> bounded separate audio -> two analyzers -> metadata or controlled stop.

#if os(macOS) && DEBUG
import AVFoundation
import ComposureCore
import Speech

/// Owns one analyzer and an eight-buffer input. Recognition text is discarded at the result boundary.
@MainActor
final class CaptureCheckSpeechChannel
{
    let transcriber: SpeechTranscriber
    let analyzer: SpeechAnalyzer
    let input: AsyncStream<AnalyzerInput>.Continuation
    private let sequence: AsyncStream<AnalyzerInput>
    private var analysisTask: Task<Void, Never>?
    private var resultTask: Task<Void, Never>?

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
        do
        {
            try await analyzer.prepareToAnalyze(in: format)
            try Task.checkCancellation()
        }
        catch
        {
            try Task.checkCancellation()
            throw CaptureCheckFailure.analyzerUnavailable
        }
    }

    func start(
        result: @escaping @MainActor @Sendable () -> Void,
        failure: @escaping @MainActor @Sendable () -> Void
    )
    {
        let analyzer = analyzer
        let sequence = sequence
        analysisTask = Task
        {
            do
            {
                try await analyzer.start(inputSequence: sequence)
            }
            catch
            {
                if !Task.isCancelled
                {
                    failure()
                }
            }
        }
        let transcriber = transcriber
        resultTask = Task
        {
            do
            {
                for try await _ in transcriber.results
                {
                    try Task.checkCancellation()
                    result()
                }
                if !Task.isCancelled
                {
                    failure()
                }
            }
            catch
            {
                if !Task.isCancelled
                {
                    failure()
                }
            }
        }
    }

    func stop() async
    {
        input.finish()
        analysisTask?.cancel()
        resultTask?.cancel()
        await analyzer.cancelAndFinishNow()
        await analysisTask?.value
        await resultTask?.value
        analysisTask = nil
        resultTask = nil
    }
}
#endif
