// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 3c3da19b-5140-4ec4-a6c0-4c8334010032
// Created: 2026
// COMPONENT: Native speech setup journey
// PURPOSE: Verify explicit setup, failure, and retry without native downloads or capture.
// RELATES: OnDeviceReadinessView, UITestReadinessProvider
// FLOW: Isolated onboarding -> passive status -> explicit setup failure -> successful retry.

import XCTest

final class ReadinessUITests: XCTestCase
{
    @MainActor
    func testExplicitSetupFailureAndRetry()
    {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-test-preferences", "--ui-test-reset-preferences", "--ui-test-readiness",
            "--ui-test-setup-failure"
        ]
        app.launch()
        finishOnboarding(in: app)
        app.buttons["Settings"].firstMatch.tap()
        verifySetupAndRetry(in: app)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Speech readiness after explicit setup"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    private func verifySetupAndRetry(in app: XCUIApplication)
    {
        let setup = app.buttons["readiness.setup"]
        reveal(setup, in: app)
        XCTAssertTrue(setup.waitForExistence(timeout: 5))
        let status = app.descendants(matching: .any).matching(identifier: "readiness.speech").firstMatch
        XCTAssertEqual(status.value as? String, "Needs setup", status.debugDescription)
        setup.tap()
        XCTAssertTrue(app.staticTexts["readiness.error"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(setup.isEnabled)
        reveal(setup, in: app)
        setup.tap()
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Ready"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        XCTAssertFalse(app.staticTexts["readiness.error"].exists)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication)
    {
        for _ in 0 ..< 8
        {
            if element.isHittable
            {
                break
            }
            app.swipeUp()
        }
    }

    @MainActor
    private func finishOnboarding(in app: XCUIApplication)
    {
        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        for _ in 0 ..< 3
        {
            next.tap()
        }
        app.buttons["onboarding.finish"].tap()
    }
}
