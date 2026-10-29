// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c163e530-260c-4040-bd3c-27f9ad993683
// Created: 2026
// COMPONENT: Capture failure mapping
// PURPOSE: Preserve separate-microphone limitations and avoid treating an uncertain stop as success.
// RELATES: MacCaptureCheck, CaptureCheckFailure
// FLOW: Framework error category -> fixed user-facing failure or explicit stop confirmation.

#if os(macOS) && DEBUG
import ComposureCore
import Foundation
import ScreenCaptureKit

/// Only explicit framework categories can confirm a stop or identify a missing microphone stream.
enum CaptureCheckErrorMapping
{
    static func failure(_ error: any Error) -> CaptureCheckFailure
    {
        if let fixed = error as? CaptureCheckFailure
        {
            return fixed
        }
        let native = error as NSError
        guard native.domain == SCStreamErrorDomain
        else
        {
            return .captureFailed
        }
        switch native.code
        {
        case SCStreamError.Code.failedToStartMicrophoneCapture.rawValue: return .microphoneUnavailable
        case SCStreamError.Code.failedToStartAudioCapture.rawValue: return .meetingAudioUnavailable
        default: return .captureFailed
        }
    }

    static func confirmsStopped(_ error: any Error) -> Bool
    {
        let native = error as NSError
        guard native.domain == SCStreamErrorDomain
        else
        {
            return false
        }
        return native.code == SCStreamError.Code.userStopped.rawValue ||
            native.code == SCStreamError.Code.systemStoppedStream.rawValue
    }
}
#endif
