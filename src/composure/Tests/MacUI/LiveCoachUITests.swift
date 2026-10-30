// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000090
// Created: 2026
// COMPONENT: Mac live coaching journey
// PURPOSE: Verify explicit controls, a floating cue, and cleanup without native capture or real preferences.
// RELATES: MacLiveCoachView, MacCuePanel, MacLiveCoachComposition
// FLOW: Isolated synthetic session -> native cue panel -> explicit Stop -> cleared idle session.

import XCTest

final class LiveCoachUITests: XCTestCase
{
    @MainActor
    func testExplicitStartShowsCueAndStopClearsSession()
    {
        continueAfterFailure = false
        let app = launch()
        let start = app.buttons["live.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertFalse(app.windows["Composure coach"].exists)
        let objective = app.textFields["live.objective"]
        XCTAssertTrue(objective.isEnabled)
        objective.click()
        objective.typeText("Clarify the promotion criteria")
        XCTAssertEqual(objective.value as? String, "Clarify the promotion criteria")
        attach(app.windows.firstMatch, name: "Objective ready before Start")
        start.click()
        let panel = app.windows["Composure coach"]
        XCTAssertTrue(panel.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertFalse(objective.isEnabled)
        XCUIApplication(bundleIdentifier: "com.apple.finder").activate()
        XCTAssertTrue(panel.staticTexts["ASK FIRST"].waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertEqual(app.state, .runningBackground)
        attach(panel, name: "Live coaching with one synthetic cue")
        panel.buttons["live.panel.stop"].click()
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: panel)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 5), .completed)
        XCTAssertEqual(objective.value as? String, "")
        XCTAssertTrue(start.isEnabled)
        XCTAssertTrue(objective.isEnabled)
        objective.click()
        objective.typeText("Agree on next steps")
        XCTAssertEqual(objective.value as? String, "Agree on next steps")
        app.terminate()
    }

    @MainActor
    func testNavigationStopsOwningSession()
    {
        continueAfterFailure = false
        let app = launch()
        let start = app.buttons["live.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.click()
        let panel = app.windows["Composure coach"]
        XCTAssertTrue(panel.waitForExistence(timeout: 8))
        app.outlines.staticTexts["Prepare"].firstMatch.click()
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: panel)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 5), .completed)
        app.terminate()
    }

    @MainActor
    private func launch() -> XCUIApplication
    {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-preferences", "--ui-test-reset-preferences", "--ui-test-live"]
        app.launch()
        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        for _ in 0 ..< 3
        {
            next.click()
        }
        app.buttons["onboarding.finish"].click()
        let live = app.outlines.staticTexts["Live Coach"].firstMatch
        XCTAssertTrue(live.waitForExistence(timeout: 5), app.debugDescription)
        live.click()
        return app
    }

    @MainActor
    private func attach(_ element: XCUIElement, name: String)
    {
        let attachment = XCTAttachment(screenshot: element.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
