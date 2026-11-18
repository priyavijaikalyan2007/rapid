// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: f9e672c9-53e1-482f-ab16-3605bdfbe20f
// COMPONENT: Native print lifecycle
// PURPOSE: Keep WebKit's print DOM alive until AppKit completes or cancels the job.
import AppKit

@MainActor final class ReaderPrintJob: NSObject
{
    private let operation: NSPrintOperation
    private let completion: (Bool) -> Void
    private(set) var result: Bool?

    init(operation: NSPrintOperation, completion: @escaping (Bool) -> Void)
    {
        self.operation = operation
        self.completion = completion
    }

    func start(window: NSWindow)
    {
        // WebKit computes pagination asynchronously. Its printing thread waits while the main run loop handles replies.
        operation.canSpawnSeparateThread = true
        operation.runModal(
            for: window,
            delegate: self,
            didRun: #selector(didFinish(_:success:context:)),
            contextInfo: nil
        )
    }

    @objc private func didFinish(_ operation: NSPrintOperation, success: Bool, context: UnsafeMutableRawPointer?)
    {
        result = success
        completion(success)
    }
}
