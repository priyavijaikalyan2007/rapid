// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 161971c4-3448-4aca-906c-a4683c50caa5
// Created: 2026
// COMPONENT: Capture failure meanings
// PURPOSE: Preserve separate-microphone limitations and require explicit stop confirmation.
// RELATES: CaptureCheckErrorMapping, MacCaptureCheck
// FLOW: Synthetic framework error category -> controlled failure or confirmed stop.

#if os(macOS) && DEBUG
import ComposureCore
@testable import ComposureModels
import Foundation
import ScreenCaptureKit
import Testing

struct CaptureCheckErrorMappingTests
{
    @Test func separateMicrophoneFailureRemainsExplicit()
    {
        let error = NSError(
            domain: SCStreamErrorDomain,
            code: SCStreamError.Code.failedToStartMicrophoneCapture.rawValue
        )
        #expect(CaptureCheckErrorMapping.failure(error) == .microphoneUnavailable)
    }

    @Test func failedStopDoesNotBecomeSuccessfulCleanup()
    {
        let error = NSError(domain: SCStreamErrorDomain, code: SCStreamError.Code.failedToStopAudioCapture.rawValue)
        #expect(!CaptureCheckErrorMapping.confirmsStopped(error))
    }

    @Test func aSystemStopConfirmsThatTheStreamEnded()
    {
        let error = NSError(domain: SCStreamErrorDomain, code: SCStreamError.Code.systemStoppedStream.rawValue)
        #expect(CaptureCheckErrorMapping.confirmsStopped(error))
    }
}
#endif
