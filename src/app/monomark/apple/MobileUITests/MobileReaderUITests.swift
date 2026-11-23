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

    func testNewDocumentTabPreservesTheLinkedHeading() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        if !app.buttons["Links"].exists
        {
            app.buttons["Document Actions"].tap()
            app.buttons["Files and Contents"].tap()
        }
        app.buttons["Links"].tap()
        let link = app.buttons["Linked section"]
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.press(forDuration: 1)
        app.buttons["Open in New Tab"].tap()
        let target = app.webViews.staticTexts["Linked section target."].firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 15))
        let destinationVisible = XCTNSPredicateExpectation(
            predicate: NSPredicate
            { _, _ in
                target.exists && !target.frame.isEmpty && app.webViews.firstMatch.frame.contains(target.frame)
            }, object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [destinationVisible], timeout: 10), .completed)
        app.buttons["Documents"].tap()
        XCTAssertTrue(app.buttons["First.md"].exists)
        XCTAssertTrue(app.buttons["Linked.md"].exists)
    }

    func testNotesRemainSeparateWhenTabsSwitchAndClose() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        writeNote("First document note.", in: app)
        openNewTab("Second.md", in: app)
        expectDocument("Mobile second document", in: app)
        writeNote("Second document note.", in: app)
        app.buttons["Documents"].tap()
        app.buttons["First.md"].tap()
        expectDocument("Mobile first document", in: app)
        XCTAssertEqual(openNotes(in: app).value as? String, "First document note.")
        app.buttons["Done"].tap()
        app.buttons["Documents"].tap()
        app.buttons["Close Tab"].tap()
        expectDocument("Mobile second document", in: app)
        XCTAssertEqual(openNotes(in: app).value as? String, "Second document note.")
        app.buttons["Done"].tap()
        openNewTab("First.md", in: app)
        expectDocument("Mobile first document", in: app)
        XCTAssertEqual(openNotes(in: app).value as? String, "First document note.")
    }

    func testFindControlsRemainReachableAfterRotation() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let actions = app.buttons["Document Actions"]
        XCTAssertTrue(actions.isHittable)
        actions.tap()
        app.buttons["Find in Document"].tap()
        let field = app.textFields["Find in document"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(field.isHittable)
        field.typeText("passage\n")
        XCTAssertTrue(app.buttons["Next"].isHittable)
        app.buttons["Done"].tap()
        expectDocument("Mobile first document", in: app)
    }

    private func writeNote(_ text: String, in app: XCUIApplication)
    {
        let editor = openNotes(in: app)
        editor.tap()
        editor.typeText(text)
        app.buttons["Done"].tap()
    }

    func testSettingsAndExportFitCompactLandscape() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        openSettings(in: app)
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Done"].isHittable)
        app.buttons["Done"].tap()
        app.buttons["Document Actions"].tap()
        app.buttons["Export and Print"].tap()
        app.buttons["Export Reading Data…"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Cancel"].isHittable)
        app.buttons["Cancel"].tap()
    }

    func testNotesCanBeEditedInCompactLandscape() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let editor = openNotes(in: app)
        XCTAssertTrue(editor.isHittable)
        editor.tap()
        editor.typeText("A landscape reading note.")
        XCTAssertTrue(app.buttons["Done"].isHittable)
        app.buttons["Done"].tap()
        XCTAssertEqual(openNotes(in: app).value as? String, "A landscape reading note.")
    }

    func testClosingNotesDismissesTheKeyboard() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        writeNote("A note before returning to the document.", in: app)
        expectKeyboardDismissed(in: app)
    }

    private func expectKeyboardDismissed(in app: XCUIApplication)
    {
        let keyboardHidden = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: app.keyboards.firstMatch
        )
        XCTAssertEqual(XCTWaiter.wait(for: [keyboardHidden], timeout: 5), .completed)
    }

    func testTouchCopyPastesDocumentTextIntoNotes() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        app.buttons["Document Actions"].tap()
        app.buttons["View and Navigation"].tap()
        app.buttons["Copy Document Path"].tap()
        selectPassage(in: app)
        editAction("Copy", in: app).tap()
        let editor = openNotes(in: app)
        paste(into: editor, in: app)
        let copied = editor.value as? String ?? ""
        XCTAssertFalse(copied.isEmpty)
        XCTAssertTrue("Select this passage for a reading note.".contains(copied))
    }

    func testTouchHighlightAndCommentSurviveRelaunch() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        selectPassage(in: app)
        app.buttons["Notes and Annotations"].tap()
        let highlight = app.buttons["Highlight"]
        XCTAssertTrue(highlight.waitForExistence(timeout: 5))
        XCTAssertTrue(highlight.isEnabled)
        highlight.tap()
        let comment = commentField(in: app)
        XCTAssertTrue(comment.waitForExistence(timeout: 5))
        comment.tap()
        comment.typeText("A comment about the passage.")
        app.buttons["Done"].tap()
        XCUIDevice.shared.press(.home)
        app.terminate()
        app.launch()
        expectDocument("Mobile first document", in: app)
        app.buttons["Notes and Annotations"].tap()
        let restoredComment = commentField(in: app)
        XCTAssertTrue(restoredComment.waitForExistence(timeout: 5))
        XCTAssertEqual(restoredComment.value as? String, "A comment about the passage.")
    }

    func testArtifactCopyControlsHaveTouchSizedTargets() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        openNewTab("Rich.md", in: app)
        expectDocument("Mobile rich content", in: app)
        let copy = tableCopy(in: app)
        XCTAssertTrue(copy.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(copy.frame.width, 44)
        XCTAssertGreaterThanOrEqual(copy.frame.height, 44)
    }

    func testTableDataPastesIntoNotesAndDiagramCopiesAsPNG() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        openNewTab("Rich.md", in: app)
        expectDocument("Mobile rich content", in: app)
        tableCopy(in: app).tap()
        let editor = openNotes(in: app)
        paste(into: editor, in: app)
        XCTAssertEqual(editor.value as? String, "Feature,Value\nLocal,Yes")
        app.buttons["Done"].tap()
        expectKeyboardDismissed(in: app)
        let png = app.webViews.buttons["Copy diagram as PNG"]
        for _ in 0 ..< 4 where !png.isHittable
        {
            app.webViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(png.isHittable)
        png.tap()
        XCTAssertTrue(app.staticTexts["Copied rendering as PNG."].waitForExistence(timeout: 10))
    }

    func testReadingDataExportOpensTheNativeFileDestination() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        let editor = openNotes(in: app)
        editor.tap()
        editor.typeText("A note to export separately.")
        app.buttons["Done"].tap()
        app.buttons["Document Actions"].tap()
        app.buttons["Export and Print"].tap()
        app.buttons["Export Reading Data…"].tap()
        let export = app.buttons["Export"]
        XCTAssertTrue(export.waitForExistence(timeout: 5))
        export.tap()
        let filename = app.textFields.matching(NSPredicate(format: "value CONTAINS 'reading-data'")).firstMatch
        XCTAssertTrue(filename.waitForExistence(timeout: 15))
        let destination = app.buttons["Monoleaf, Actions Menu"]
        if !destination.waitForExistence(timeout: 5)
        {
            let localFolder = app.staticTexts["Monoleaf"].firstMatch
            XCTAssertTrue(localFolder.waitForExistence(timeout: 10))
            localFolder.tap()
        }
        XCTAssertTrue(destination.waitForExistence(timeout: 5))
        filename.tap()
        filename.typeText("monoleaf-export-" + UUID().uuidString)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Exported a copy. The original Markdown is unchanged."]
            .waitForExistence(timeout: 10))
        expectDocument("Mobile first document", in: app)
    }

    private func selectPassage(in app: XCUIApplication)
    {
        let passage = app.webViews.staticTexts["Select this passage for a reading note."].firstMatch
        XCTAssertTrue(passage.waitForExistence(timeout: 5))
        passage.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).press(forDuration: 1)
    }

    private func editAction(_ title: String, in app: XCUIApplication) -> XCUIElement
    {
        let menu = app.menuItems[title].firstMatch
        if menu.waitForExistence(timeout: 1)
        {
            return menu
        }
        let button = app.buttons[title].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        return button
    }

    private func paste(into editor: XCUIElement, in app: XCUIApplication)
    {
        editor.tap()
        editor.press(forDuration: 1)
        editAction("Paste", in: app).tap()
    }

    private func tableCopy(in app: XCUIApplication) -> XCUIElement
    {
        let full = app.webViews.buttons["Copy entire table as CSV"].firstMatch
        return full.exists ? full : app.webViews.buttons["Copy table as CSV"].firstMatch
    }

    private func commentField(in app: XCUIApplication) -> XCUIElement
    {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'annotation-comment-'"))
            .firstMatch
    }

    func testReaderSettingsSurviveRelaunch() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        openSettings(in: app)
        let gutter = app.switches["Show source line numbers"]
        XCTAssertTrue(gutter.waitForExistence(timeout: 5))
        gutter.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let enabled = expectation(for: NSPredicate(format: "value == '1'"), evaluatedWith: gutter)
        wait(for: [enabled], timeout: 3)
        app.buttons["Done"].tap()
        app.terminate()
        app.launch()
        expectDocument("Mobile first document", in: app)
        openSettings(in: app)
        XCTAssertEqual(app.switches["Show source line numbers"].value as? String, "1")
    }

    func testNotesSurviveBackgroundAndRelaunch() throws
    {
        let app = exampleApplication()
        app.launch()
        expectDocument("Mobile first document", in: app)
        let editor = openNotes(in: app)
        editor.tap()
        editor.typeText("A local mobile reading note.")
        app.buttons["Done"].tap()
        XCUIDevice.shared.press(.home)
        app.terminate()
        app.launch()
        expectDocument("Mobile first document", in: app)
        XCTAssertEqual(openNotes(in: app).value as? String, "A local mobile reading note.")
    }

    private func exampleApplication() -> XCUIApplication
    {
        let app = XCUIApplication()
        app.launchArguments = ["--smoke-test", "--mobile-ui-test", "--mobile-test-session", UUID().uuidString]
        return app
    }

    private func openSettings(in app: XCUIApplication)
    {
        app.buttons["Document Actions"].tap()
        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()
    }

    private func openNotes(in app: XCUIApplication) -> XCUIElement
    {
        app.buttons["Notes and Annotations"].tap()
        let notes = app.buttons["Notes"]
        XCTAssertTrue(notes.waitForExistence(timeout: 5))
        notes.tap()
        let editor = app.textViews["reading-notes"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        return editor
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
        let row = app.buttons[name]
        if !row.exists || !row.isHittable
        {
            app.buttons["Document Actions"].tap()
            app.buttons["Files and Contents"].tap()
        }
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
