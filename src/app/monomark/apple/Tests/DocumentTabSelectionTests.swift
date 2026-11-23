// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: a9c07222-c238-466f-bf63-674ec898c3cd
// COMPONENT: Stable document tab selection tests
// PURPOSE: Preserve the active document when asynchronous close operations finish after another selection.
// FLOW: Ordered document identities -> selection or closure -> stable surviving tab.
import XCTest
@testable import MonoMarkCore

final class DocumentTabSelectionTests: XCTestCase
{
    func testOpeningSelectsTheNewDocument()
    {
        var tabs = DocumentTabSelection(first: UUID())
        let second = UUID()
        tabs.append(second)
        XCTAssertEqual(tabs.selectedID, second)
    }

    func testClosingABackgroundTabPreservesTheSelectedDocument()
    {
        let first = UUID()
        let second = UUID()
        let third = UUID()
        var tabs = DocumentTabSelection(first: first)
        tabs.append(second)
        tabs.append(third)
        XCTAssertTrue(tabs.remove(second))
        XCTAssertEqual(tabs.selectedID, third)
    }

    func testClosingTheCurrentTabSelectsItsNextNeighbor()
    {
        let first = UUID()
        let second = UUID()
        let third = UUID()
        var tabs = DocumentTabSelection(first: first)
        tabs.append(second)
        tabs.append(third)
        XCTAssertTrue(tabs.select(second))
        XCTAssertTrue(tabs.remove(second))
        XCTAssertEqual(tabs.selectedID, third)
    }

    func testTheLastDocumentCannotBeRemoved()
    {
        let first = UUID()
        var tabs = DocumentTabSelection(first: first)
        XCTAssertFalse(tabs.remove(first))
        XCTAssertEqual(tabs.ids, [first])
    }

    func testAnUnknownSelectionDoesNotReplaceTheCurrentDocument()
    {
        let first = UUID()
        var tabs = DocumentTabSelection(first: first)
        XCTAssertFalse(tabs.select(UUID()))
        XCTAssertEqual(tabs.selectedID, first)
    }

    func testAppendingAnExistingIdentityDoesNotDuplicateATab()
    {
        let first = UUID()
        var tabs = DocumentTabSelection(first: first)
        tabs.append(first)
        XCTAssertEqual(tabs.ids, [first])
    }
}
