// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File a90348bf-c714-4889-bc1b-ae19f0292a14: a90348bf-c714-4889-bc1b-ae19f0292a14
// Created: 2026
// COMPONENT: Resource catalog boundary tests
// PURPOSE: Reject unsafe metadata before it reaches cache paths or native parsers.
// RELATES: ResourceCatalogPolicy
// FLOW: Catalog fixture -> validation -> accepted value or failure.

import Foundation
import XCTest

/// Checks untrusted catalog metadata without issuing network requests.
final class ResourceCatalogPolicyTests: XCTestCase
{
    /// Accepts supported licensed font metadata.
    func testValidFont() throws
    {
        XCTAssertNoThrow(try ResourceCatalogPolicy.validate(resource()))
    }

    /// Rejects executable and credential-bearing attribution links.
    func testUnsafeAttributionAddress() throws
    {
        XCTAssertThrowsError(try ResourceCatalogPolicy.validate(resource(source: "javascript:alert(1)")))
        XCTAssertThrowsError(try ResourceCatalogPolicy.validate(resource(source: "https://user:password@example.com/")))
    }

    /// Bounds file-name length and excludes parent-directory identifiers.
    func testUnsafeIdentifiers() throws
    {
        for identifier in ["..", "../frame", String(repeating: "a", count: 129)]
        {
            XCTAssertThrowsError(try ResourceCatalogPolicy.validate(resource(id: identifier)))
        }
    }

    /// Rejects an oversized catalog and ambiguous duplicate cache keys.
    func testCatalogBounds() throws
    {
        XCTAssertThrowsError(try ResourceCatalogPolicy.validate(RemoteResourceCatalog(version: 1, resources: [])))
        XCTAssertThrowsError(try ResourceCatalogPolicy.validate(RemoteResourceCatalog(
            version: 1,
            resources: [resource(), resource()]
        )))
        let entries = try (0 ... 250).map
        {
            try resource(id: "font-\($0)")
        }
        XCTAssertThrowsError(try ResourceCatalogPolicy.validate(RemoteResourceCatalog(version: 1, resources: entries)))
    }

    /// Keeps all fixture addresses local to tests without retrieving their contents.
    private func resource(
        id: String = "example-font",
        source: String = "https://example.com/font"
    ) throws -> RemoteResource
    {
        RemoteResource(
            id: id,
            name: "Example",
            kind: .font,
            creator: "Example Author",
            sourceURL: try XCTUnwrap(URL(string: source)),
            downloadURL: try XCTUnwrap(URL(string: "https://example.com/font.ttf")),
            licenseName: "OFL-1.1",
            licenseURL: try XCTUnwrap(URL(string: "https://example.com/license")),
            notes: nil,
            fontName: "Example-Regular"
        )
    }
}
