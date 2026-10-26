// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 8047cf10-5907-4127-85b5-c75f54891936
// Created: 2026
// COMPONENT: Native Prepare journey tests
// PURPOSE: Verify profile guidance and removal of sensitive preparation across app lifecycle changes.
// RELATES: PrepareView, PreparationCoordinator
// FLOW: Synthetic topic -> labeled guidance -> clear, background, and relaunch checks.

import XCTest

final class PrepareUITests: XCTestCase
{
    @MainActor
    func testPreparationClearsOnBackgroundAndRelaunch()
    {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-preferences", "--ui-test-reset-preferences", "--ui-test-model-unavailable"]
        app.launch()
        completeFirstRun(in: app)
        verifyGuidance(in: app)
        attachResult(in: app)
        app.buttons["prepare.clear"].tap()
        XCTAssertFalse(app.staticTexts["Objective"].exists)
        verifyBackgroundClearing(in: app)
        verifyRelaunchClearing(in: app)
    }

    @MainActor
    private func completeFirstRun(in app: XCUIApplication)
    {
        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        for _ in 0 ..< 3
        {
            next.tap()
        }
        app.buttons["onboarding.finish"].tap()
    }

    @MainActor
    private func attachResult(in app: XCUIApplication)
    {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Profile-based preparation"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    private func verifyBackgroundClearing(in app: XCUIApplication)
    {
        verifyGuidance(in: app)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertFalse(app.staticTexts["Objective"].exists)
        XCTAssertEqual(app.textViews["prepare.topic"].firstMatch.value as? String, "")
    }

    @MainActor
    private func verifyRelaunchClearing(in app: XCUIApplication)
    {
        verifyGuidance(in: app)
        app.terminate()
        app.launchArguments = ["--ui-test-preferences", "--ui-test-model-unavailable"]
        app.launch()
        XCTAssertTrue(app.textViews["prepare.topic"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.textViews["prepare.topic"].firstMatch.value as? String, "")
        XCTAssertFalse(app.staticTexts["Objective"].exists)
    }

    @MainActor
    private func verifyGuidance(in app: XCUIApplication)
    {
        let topic = app.textViews["prepare.topic"].firstMatch
        XCTAssertTrue(topic.waitForExistence(timeout: 5))
        topic.tap()
        topic.typeText("Synthetic review conversation")
        app.buttons["prepare.generate"].tap()
        XCTAssertTrue(app.staticTexts["Objective"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Profile guidance"].exists)
    }
}
