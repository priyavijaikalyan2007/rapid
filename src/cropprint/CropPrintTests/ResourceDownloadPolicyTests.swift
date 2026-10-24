// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 8c29fb80-0ee5-41ee-88dc-4ed940b31432
// Created: 2026
// COMPONENT: ResourceDownloadPolicyTests
// PURPOSE: Verifies ResourceDownloadPolicy contracts and failure boundaries.
// RELATES: [[CropPrint]]
// FLOW: Test scenario -> contract -> XCTest result.

import Foundation
import XCTest

/// Verifies ResourceDownloadPolicy contracts and failure boundaries.
final class ResourceDownloadPolicyTests: XCTestCase
{
    /// Verifies cancelled collection does not return an empty success.
    func testCancelledCollectionDoesNotReturnAnEmptySuccess() async
    {
        let bytes = AsyncStream<UInt8>
        {
            $0.finish()
        }
        let task = Task.detached
        {
            withUnsafeCurrentTask
            {
                $0?.cancel()
            }
            return try await ResourceDownloadPolicy.collect(bytes, maximumBytes: 2)
        }
        do
        {
            _ = try await task.value
            XCTFail("Cancellation must remain distinguishable from an empty resource.")
        }
        catch
        {
            XCTAssertTrue(error is CancellationError)
        }
    }

    /// Verifies an address with credentials is rejected.
    func testAnAddressWithCredentialsIsRejected() throws
    {
        let address = try XCTUnwrap(URL(string: "https://user:secret@example.com/font.ttf"))
        XCTAssertThrowsError(try ResourceDownloadPolicy.validateAddress(address))
    }

    /// Verifies an insecure address is rejected.
    func testAnInsecureAddressIsRejected() throws
    {
        let address = try XCTUnwrap(URL(string: "http://example.com/font.ttf"))
        XCTAssertThrowsError(try ResourceDownloadPolicy.validateAddress(address))
    }

    /// Verifies secure address is accepted.
    func testSecureAddressIsAccepted() throws
    {
        let address = try XCTUnwrap(URL(string: "https://example.com/font.ttf"))
        XCTAssertNoThrow(try ResourceDownloadPolicy.validateAddress(address))
    }

    /// Verifies collection stops at the byte limit.
    func testCollectionStopsAtTheByteLimit() async throws
    {
        let bytes = AsyncStream<UInt8>
        {
            continuation in
            for value in [UInt8(1), 2, 3]
            {
                continuation.yield(value)
            }
            continuation.finish()
        }
        do
        {
            _ = try await ResourceDownloadPolicy.collect(bytes, maximumBytes: 2)
            XCTFail("An oversized response must be rejected.")
        }
        catch
        {
            XCTAssertEqual(error as? ResourceDownloadPolicy.Failure, .fileTooLarge)
        }
    }

    /// Verifies collection accepts the exact byte limit.
    func testCollectionAcceptsTheExactByteLimit() async throws
    {
        let bytes = AsyncStream<UInt8>
        {
            continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }
        let data = try await ResourceDownloadPolicy.collect(bytes, maximumBytes: 2)
        XCTAssertEqual(data, Data([1, 2]))
    }

    /// Verifies an advertised oversized response is rejected.
    func testAnAdvertisedOversizedResponseIsRejected() throws
    {
        let address = try XCTUnwrap(URL(string: "https://example.com/font.ttf"))
        let response = try XCTUnwrap(HTTPURLResponse(
            url: address, statusCode: 200, httpVersion: nil, headerFields: ["Content-Length": "100"]
        ))
        XCTAssertThrowsError(try ResourceDownloadPolicy.validateResponse(response, maximumBytes: 10))
    }

    /// Rejects an unsuccessful HTTP status before retaining response bytes.
    func testHTTPFailureAndInvalidLimit() throws
    {
        let url = try XCTUnwrap(URL(string: "https://example.com/font.ttf"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
        XCTAssertThrowsError(try ResourceDownloadPolicy.validateResponse(response, maximumBytes: 10))
        XCTAssertThrowsError(try ResourceDownloadPolicy.validateResponse(response, maximumBytes: 0))
    }

    /// Rejects invalid memory budgets even when the remote sequence has no bytes.
    func testInvalidCollectionLimit() async
    {
        let bytes = AsyncStream<UInt8>
        {
            $0.finish()
        }
        do
        {
            _ = try await ResourceDownloadPolicy.collect(bytes, maximumBytes: 0)
            XCTFail("The budget must be positive.")
        }
        catch
        {
            XCTAssertEqual(error as? ResourceDownloadPolicy.Failure, .invalidLimit)
        }
    }
}
