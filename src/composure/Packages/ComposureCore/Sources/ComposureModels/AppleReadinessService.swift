// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c82a9923-cfe5-40f3-a23e-8aefaae23703
// Created: 2026
// COMPONENT: Native device readiness
// PURPOSE: Inspect native prerequisites and install speech assets only through explicit setup.
// RELATES: ReadinessProvider, ReadinessCoordinator
// FLOW: Apple status APIs -> typed readiness -> explicitly requested system asset installation.

import AVFoundation
import ComposureCore
import Foundation
import Speech
#if os(macOS)
import CoreGraphics
#endif

/// Asset setup contacts Apple's system asset service only after the caller's explicit setup action.
public actor AppleReadinessService: ReadinessProvider
{
    private let model: any CoachingModel
    private var isInstalling = false

    public init(model: any CoachingModel = AppleFoundationCoachingModel())
    {
        self.model = model
    }

    public func snapshot() async -> DeviceReadiness
    {
        let (speech, locale) = await speechStatus()
        return await DeviceReadiness(
            speech: speech,
            model: model.readiness(),
            microphone: AppleReadinessMapping.microphone(AVCaptureDevice.authorizationStatus(for: .audio)),
            meetingAudio: meetingAudioPermission(),
            speechLocaleIdentifier: locale
        )
    }

    public func setUpSpeech(progress: @escaping @Sendable (Double?) async -> Void) async throws
    {
        guard !isInstalling
        else
        {
            throw ReadinessError.busy
        }
        isInstalling = true
        defer { isInstalling = false }
        do
        {
            try Task.checkCancellation()
            guard let module = await makeModule()
            else
            {
                throw ReadinessError.unsupported
            }
            try Task.checkCancellation()
            guard let request = try await AssetInventory.assetInstallationRequest(supporting: [module])
            else
            {
                return
            }
            try Task.checkCancellation()
            try await install(request, progress: progress)
        }
        catch
        {
            try Task.checkCancellation()
            throw error as? ReadinessError ?? .installationFailed
        }
    }

    private func install(
        _ request: AssetInstallationRequest,
        progress: @escaping @Sendable (Double?) async -> Void
    ) async throws
    {
        let monitor = Task
        {
            while !Task.isCancelled
            {
                let value = request.progress
                await progress(value.totalUnitCount > 0 ? value.fractionCompleted : nil)
                try await Task.sleep(for: .milliseconds(250))
            }
        }
        defer { monitor.cancel() }
        try await request.downloadAndInstall()
    }

    private func makeModule() async -> SpeechTranscriber?
    {
        guard SpeechTranscriber.isAvailable
        else
        {
            return nil
        }
        let supported = await SpeechTranscriber.supportedLocales
        guard let locale = AppleReadinessMapping.englishLocale(from: supported, preferred: .current)
        else
        {
            return nil
        }
        return SpeechTranscriber(locale: locale, preset: .timeIndexedProgressiveTranscription)
    }

    private func speechStatus() async -> (SpeechAssetState, String?)
    {
        guard SpeechTranscriber.isAvailable
        else
        {
            return (.unavailable, nil)
        }
        guard let module = await makeModule()
        else
        {
            return (.unsupportedLocale, nil)
        }
        let status = await AssetInventory.status(forModules: [module])
        return (AppleReadinessMapping.speech(status), module.selectedLocales.first?.identifier)
    }

    private func meetingAudioPermission() -> CapturePermissionState
    {
        #if os(macOS)
        return AppleReadinessMapping.meetingAudio(granted: CGPreflightScreenCaptureAccess())
        #else
        return .notApplicable
        #endif
    }
}
