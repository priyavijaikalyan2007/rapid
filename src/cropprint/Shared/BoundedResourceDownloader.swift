// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 0fe7c2e4-7750-46ff-bf1c-bc5e71abc84a
// Created: 2026
// COMPONENT: BoundedResourceDownloader
// PURPOSE: Defines the BoundedResourceDownloader domain values and their contracts.
// RELATES: [[CropPrint]]
// FLOW: Native application -> BoundedResourceDownloader -> local result.

import Foundation

/// Downloads optional public resources without persistent cookies or an unbounded response buffer.
struct BoundedResourceDownloader
{
    /// Allows stalled individual requests to stop before a full transfer timeout.
    private static let requestTimeout: TimeInterval = 30
    /// Caps the lifetime of each user-requested resource transfer.
    private static let resourceTimeout: TimeInterval = 60

    /// Returns bounded data and cancels the network task on success, failure, or cancellation.
    func data(from address: URL, maximumBytes: Int) async throws -> Data
    {
        try ResourceDownloadPolicy.validateAddress(address)
        let session = URLSession(configuration: Self.configuration())
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(from: address, delegate: ResourceRedirectPolicy())
        defer { bytes.task.cancel() }
        try ResourceDownloadPolicy.validateResponse(response, maximumBytes: maximumBytes)
        return try await ResourceDownloadPolicy.collect(bytes, maximumBytes: maximumBytes)
    }

    /// Disables persistent state because catalog requests do not require an account or tracking.
    private static func configuration() -> URLSessionConfiguration
    {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = resourceTimeout
        return configuration
    }
}
