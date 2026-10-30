// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000075
// Created: 2026
// COMPONENT: Native capture lifecycle tests
// PURPOSE: Verify passive creation and idempotent cleanup without requesting capture or permissions.
// RELATES: MacMeetingAudioSource
// FLOW: Passive source -> cancellation and cleanup -> confirmed stopped state.

#if os(macOS)
import Testing
@testable import ComposureModels

@MainActor
struct MacMeetingAudioSourceTests
{
    @Test func passiveSourceStopsWithoutStartingNativeResources() async
    {
        let source = MacMeetingAudioSource()
        source.cancelStart()
        #expect(await source.stop())
        #expect(await source.stop())
    }
}
#endif
