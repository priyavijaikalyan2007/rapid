// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 98dddd1e-16a7-4ec2-9243-b3b3fd232477
// Created: 2026
// COMPONENT: ResourceDownloadPolicy
// PURPOSE: Checks HTTPS transport, HTTP responses, cancellation, and streamed byte limits.
// RELATES: [[CropPrint]]
// FLOW: Native application -> ResourceDownloadPolicy -> local result.

import Foundation

/// Validates transport boundaries before downloaded bytes enter a catalog or resource cache.
enum ResourceDownloadPolicy
{
    /// User-requested JSON catalogs have a smaller limit than font and frame files.
    static let maximumCatalogBytes = 1_000_000
    /// Bounds memory retained by a single optional resource download.
    static let maximumResourceBytes = 25_000_000
    /// Avoids reserving the full transfer limit for small responses.
    private static let initialBufferBytes = 65_536

    /// Failures belong to this policy's validation contract.
    enum Failure: LocalizedError
    {
        case insecureAddress
        case badResponse
        case fileTooLarge
        case invalidLimit

        var errorDescription: String?
        {
            switch self
            {
            case .insecureAddress:
                "The resource address is not secure. Use an HTTPS address without a username or password."
            case .badResponse:
                "The server did not return a valid resource. Check the catalog address and try again."
            case .fileTooLarge:
                "The download exceeds the resource limit. Choose a smaller file or catalog."
            case .invalidLimit:
                "The download limit is invalid. Restart the application and try again."
            }
        }
    }

    /// Rejects executable schemes, missing hosts, and credentials embedded in addresses.
    static func validateAddress(_ address: URL) throws
    {
        guard address.scheme?.lowercased() == "https", address.host?.isEmpty == false,
              address.user == nil, address.password == nil
        else
        {
            throw Failure.insecureAddress
        }
    }

    /// Checks the final address, status, and advertised size before consuming the body.
    static func validateResponse(_ response: URLResponse, maximumBytes: Int) throws
    {
        try Task.checkCancellation()
        guard maximumBytes > 0
        else
        {
            throw Failure.invalidLimit
        }
        guard let response = response as? HTTPURLResponse,
              (200 ..< 300).contains(response.statusCode), let address = response.url
        else
        {
            throw Failure.badResponse
        }
        try validateAddress(address)
        guard response.expectedContentLength <= Int64(maximumBytes)
        else
        {
            throw Failure.fileTooLarge
        }
    }

    /// Stops at the byte limit even when the server omits or understates Content-Length.
    static func collect<Bytes: AsyncSequence>(_ bytes: Bytes, maximumBytes: Int) async throws -> Data
        where Bytes.Element == UInt8
    {
        guard maximumBytes > 0
        else
        {
            throw Failure.invalidLimit
        }
        var result = Data()
        result.reserveCapacity(min(maximumBytes, initialBufferBytes))
        for try await byte in bytes
        {
            try Task.checkCancellation()
            guard result.count < maximumBytes
            else
            {
                throw Failure.fileTooLarge
            }
            result.append(byte)
        }
        try Task.checkCancellation()
        return result
    }
}
