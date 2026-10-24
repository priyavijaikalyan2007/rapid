// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: cd8e1e62-af72-4d3e-b39e-8a79109f2a45
// Created: 2026
// COMPONENT: Cancellable preview work
// PURPOSE: Propagate edit cancellation to detached native image processing.
// RELATES: ResourceLibrary, PhotoDocument, MobilePhotoDocument
// FLOW: Validated input -> bounded local work -> recoverable result.

import Foundation
import CoreGraphics

/// Debounces previews and propagates cancellation to work outside the main actor.
enum PhotoProcessingTask
{
    /// Coalesces rapid slider changes before running the expensive native pipeline.
    private static let debounceNanoseconds: UInt64 = 120_000_000

    /// Returns an edit only after both the caller and renderer complete without cancellation.
    static func render(
        source: CGImage,
        settings: PhotoAdjustmentSettings,
        cachedMask: CGImage?
    ) async throws -> PhotoProcessingResult
    {
        try await Task.sleep(nanoseconds: debounceNanoseconds)
        let worker = Task.detached(priority: .userInitiated)
        {
            try LocalPhotoProcessor.render(source: source, settings: settings, cachedPersonMask: cachedMask)
        }
        return try await withTaskCancellationHandler
        {
            let result = try await worker.value
            try Task.checkCancellation()
            return result
        }
        onCancel: {
            worker.cancel()
        }
    }
}
