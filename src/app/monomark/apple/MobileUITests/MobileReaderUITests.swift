// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 9de61d1d-7580-497c-9793-079e92bf36ed
// COMPONENT: Monoleaf mobile native acceptance
// PURPOSE: Exercise real phone/tablet controls with isolated synthetic reading data.
// FLOW: XCTest launch -> native scene -> reader and document actions.
import XCTest

@MainActor
final class MobileReaderUITests: XCTestCase
{
    override func setUpWithError() throws
    {
        continueAfterFailure = false
    }

    func testThreeDocumentTabsRenderAndSwitchIndependently() throws
    {
        let app = XCUIApplication()
        app.launchArguments = ["--smoke-test", "--mobile-ui-test"]
        app.launch()
        expectDocument("Mobile first document", in: app)
        openNewTab("Second.md", in: app)
        expectDocument("Mobile second document", in: app)
        openNewTab("Third.md", in: app)
        expectDocument("Mobile third document", in: app)
        app.buttons["Documents"].tap()
        app.buttons["First.md"].tap()
        expectDocument("Mobile first document", in: app)
        app.buttons["Documents"].tap()
        app.buttons["Second.md"].tap()
        expectDocument("Mobile second document", in: app)
    }

    private func expectDocument(_ title: String, in app: XCUIApplication)
    {
        XCTAssertTrue(app.webViews.staticTexts[title].firstMatch.waitForExistence(timeout: 15))
    }

    private func openNewTab(_ name: String, in app: XCUIApplication)
    {
        app.buttons["Document Actions"].tap()
        app.buttons["Files and Contents"].tap()
        let row = app.buttons[name]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.press(forDuration: 1)
        app.buttons["Open in New Tab"].tap()
    }

    func testCompactToolbarKeepsDocumentActionsReachable() throws
    {
        let app = XCUIApplication()
        app.launchArguments = ["--smoke-test"]
        app.launch()
        let actions = app.buttons["Document Actions"]
        XCTAssertTrue(actions.waitForExistence(timeout: 10))
        XCTAssertTrue(actions.isHittable)
        actions.tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Find in Document"].exists)
    }

    func testInitialReaderShowsOpenFileAndFolder() throws
    {
        let app = XCUIApplication()
        app.launchArguments = ["--smoke-test"]
        app.launch()
        XCTAssertTrue(app.buttons["Open File"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Open Folder"].isHittable)
    }
}
