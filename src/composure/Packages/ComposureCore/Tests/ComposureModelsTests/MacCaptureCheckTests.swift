// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 2fb9e918-f756-456e-b310-129ba0598628
// Created: 2026
// COMPONENT: Native capture-check boundaries
// PURPOSE: Verify bounded conversion and passive lifecycle without recording or requesting capture.
// RELATES: MacCaptureCheck, CaptureCheckAudioConverter
// FLOW: Synthetic PCM or idle state -> native adapter -> independent boundary assertions.

#if os(macOS) && DEBUG
import ComposureCore
@testable import ComposureModels
import Testing

@MainActor
struct MacCaptureCheckTests
{
    @Test func constructingTheCheckDoesNotStartCapture()
    {
        let check = MacCaptureCheck()
        #expect(check.state == .idle)
        #expect(check.metrics.microphoneBuffers == 0 && check.metrics.meetingBuffers == 0)
    }

    @Test func stoppingAnIdleCheckDoesNotChangeItsState() async
    {
        let check = MacCaptureCheck()
        await check.stop()
        #expect(check.state == .idle)
    }

    @Test func cancellationCannotSkipCaptureCleanup() async
    {
        let operation = Task
        { @MainActor in
            #expect(Task.isCancelled)
            return await MacCaptureCheck.finishCleanup
            {
                !Task.isCancelled
            }
        }
        operation.cancel()
        #expect(await operation.value)
    }
}
#endif
