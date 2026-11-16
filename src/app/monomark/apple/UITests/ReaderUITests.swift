// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: beed1447-5b99-407a-a453-96e5aed02f19
// COMPONENT: MonoMark native acceptance tests
// PURPOSE: Verify core native reading and keyboard journeys in the actual application.
import XCTest

@MainActor
final class ReaderUITests: XCTestCase
{
    func testDocumentLocationRemainsOpenForCopy() throws
    {
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        let location = app.buttons["Document Location"]
        XCTAssertTrue(location.waitForExistence(timeout: 15))
        location.click()
        let copy = app.buttons["Copy Path"]
        XCTAssertTrue(copy.waitForExistence(timeout: 5))
        copy.hover()
        XCTAssertTrue(copy.exists)
        copy.click()
        XCTAssertTrue(app.staticTexts["Copied"].waitForExistence(timeout: 5))
    }

    func testReadingSidebarAndSettings() throws
    {
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        XCTAssertTrue(app.buttons["Contents"].waitForExistence(timeout: 15))
        app.buttons["Contents"].click()
        XCTAssertTrue(app.staticTexts["MonoMark"].firstMatch.waitForExistence(timeout: 15))
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(app.staticTexts["Typography"].waitForExistence(timeout: 5))
    }

    func testEscapeDoesNotCloseOrdinaryWindow() throws
    {
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(app.windows.firstMatch.exists)
    }
}
