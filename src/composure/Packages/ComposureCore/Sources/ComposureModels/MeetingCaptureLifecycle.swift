// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000083
// Created: 2026
// COMPONENT: Mac live audio capture
// PURPOSE: Stream separate bounded audio into ephemeral on-device speech with explicit cleanup.
// RELATES: LiveSessionCoordinator, MacMeetingAudioSource, MeetingSpeechChannel
// FLOW: Explicit Start and picker -> transient audio -> two analyzers -> confirmed Stop.

#if os(macOS)
import AppKit
import ComposureCore
import CoreAudio

/// Watches platform lifecycle and default routes without changing system audio configuration.
@MainActor
final class MeetingCaptureLifecycle
{
    private var observers: [NSObjectProtocol] = []
    private var listener: AudioObjectPropertyListenerBlock?
    private let selectors = [kAudioHardwarePropertyDefaultInputDevice, kAudioHardwarePropertyDefaultOutputDevice]

    func watch(stop: @escaping @MainActor @Sendable () -> Void) throws
    {
        let center = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.willSleepNotification,
            NSWorkspace.screensDidSleepNotification,
            NSWorkspace.sessionDidResignActiveNotification
        ]
        {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main)
            { _ in
                Task
                { @MainActor in
                    stop()
                }
            })
        }
        let callback: AudioObjectPropertyListenerBlock = { _, _ in
            Task
            { @MainActor in
                stop()
            }
        }
        listener = callback
        for selector in selectors
        {
            var property = address(selector)
            guard AudioObjectAddPropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject), &property, .main, callback
            ) == noErr else
            {
                throw CaptureCheckFailure.captureFailed
            }
        }
    }

    func clear()
    {
        let center = NSWorkspace.shared.notificationCenter
        for observer in observers
        {
            center.removeObserver(observer)
        }
        observers = []
        if let listener
        {
            for selector in selectors
            {
                var property = address(selector)
                AudioObjectRemovePropertyListenerBlock(
                    AudioObjectID(kAudioObjectSystemObject), &property, .main, listener
                )
            }
        }
        listener = nil
    }

    private func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress
    {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }
}
#endif
