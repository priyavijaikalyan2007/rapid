// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: bdcb02de-6735-47a3-885f-9b8b483c08a0
// Created: 2026
// COMPONENT: Debug Mac capture experiment
// PURPOSE: Check separate transient audio streams with bounded processing and no recording output.
// RELATES: MacCaptureCheck, CaptureCheckMetrics
// FLOW: Explicit capture start -> bounded separate audio -> two analyzers -> metadata or controlled stop.

#if os(macOS)
import ScreenCaptureKit

/// Bridges unspecified native callback queues to the main actor without changing the selected filter.
final class CaptureCheckPicker: NSObject, SCContentSharingPickerObserver
{
    /// The immutable selected filter is retained solely for transfer. This adapter never mutates it.
    private struct Selection: @unchecked Sendable
    {
        let filter: SCContentFilter?
    }

    private let selection: @MainActor @Sendable (SCContentFilter?) -> Void
    private let failure: @MainActor @Sendable () -> Void

    init(
        selection: @escaping @MainActor @Sendable (SCContentFilter?) -> Void,
        failure: @escaping @MainActor @Sendable () -> Void
    )
    {
        self.selection = selection
        self.failure = failure
    }

    @MainActor func show()
    {
        let picker = SCContentSharingPicker.shared
        var configuration = SCContentSharingPickerConfiguration()
        configuration.allowedPickerModes = [.singleApplication]
        if let identifier = Bundle.main.bundleIdentifier
        {
            configuration.excludedBundleIDs = [identifier]
        }
        picker.defaultConfiguration = configuration
        picker.add(self)
        picker.isActive = true
        picker.present()
    }

    @MainActor func close()
    {
        let picker = SCContentSharingPicker.shared
        picker.remove(self)
        picker.isActive = false
    }

    func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?)
    {
        deliver(nil)
    }

    func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didUpdateWith filter: SCContentFilter,
        for stream: SCStream?
    )
    {
        deliver(filter)
    }

    func contentSharingPickerStartDidFailWithError(_ error: any Error)
    {
        let failure = failure
        Task
        { @MainActor in
            failure()
        }
    }

    private func deliver(_ filter: SCContentFilter?)
    {
        let value = Selection(filter: filter)
        let selection = selection
        Task
        { @MainActor in
            selection(value.filter)
        }
    }
}
#endif
