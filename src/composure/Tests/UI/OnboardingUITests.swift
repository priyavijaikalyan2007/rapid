// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 33d2ac66-2ca4-42cd-a840-24ebd57a676f
// Created: 2026
// COMPONENT: Native onboarding journey tests
// PURPOSE: Verify privacy steps, profile editing, and restoration across application relaunch.
// RELATES: OnboardingView, CoachingSettingsView, AppPreferencesComposition
// FLOW: Isolated UI-test preferences -> native controls -> relaunch -> restored choices.

import XCTest

/// Exercises the real mobile app through accessibility controls, using synthetic preferences only.
final class OnboardingUITests: XCTestCase
{
    @MainActor
    func testFirstRunCompletesAndRestoresChoices()
    {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-preferences", "--ui-test-reset-preferences"]
        app.launch()
        completeOnboarding(in: app)
        app.terminate()

        app.launchArguments = ["--ui-test-preferences"]
        app.launch()
        openSettings(in: app)

        let restraint = app.switches["profile.executiveRestraint"]
        reveal(restraint, in: app)
        XCTAssertEqual(restraint.value as? String, "1")
        XCTAssertFalse(app.buttons["onboarding.next"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Restored coaching profile"
        attachment.lifetime = .keepAlways
        add(attachment)
        verifySettingsActions(in: app)
    }

    @MainActor
    private func completeOnboarding(in app: XCUIApplication)
    {
        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap()
        XCTAssertTrue(app.staticTexts["Private by design"].exists)
        next.tap()
        app.buttons["onboarding.back"].tap()
        XCTAssertTrue(app.staticTexts["Private by design"].exists)
        next.tap()
        next.tap()

        let restraint = app.switches["profile.executiveRestraint"]
        reveal(restraint, in: app)
        // SwiftUI exposes a row and a nested native switch. Activate the control, not the row's label.
        let control = restraint.switches.firstMatch
        XCTAssertTrue(control.exists, restraint.debugDescription)
        control.tap()
        XCTAssertEqual(restraint.value as? String, "1")
        app.buttons["onboarding.finish"].tap()
        XCTAssertTrue(app.buttons["Settings"].firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    private func verifySettingsActions(in app: XCUIApplication)
    {
        let restraint = app.switches["profile.executiveRestraint"]
        restraint.switches.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Unsaved changes"].exists)
        app.buttons["Discard changes"].tap()
        XCTAssertEqual(restraint.value as? String, "1")

        restraint.switches.firstMatch.tap()
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Preferences saved"].exists)
        app.terminate()
        app.launch()
        openSettings(in: app)
        reveal(restraint, in: app)
        XCTAssertEqual(restraint.value as? String, "0")
        restraint.switches.firstMatch.tap()
        app.buttons["Save"].tap()
        verifyReset(in: app)
    }

    @MainActor
    private func verifyReset(in app: XCUIApplication)
    {
        let reset = app.buttons["Reset coaching profile"]
        reveal(reset, in: app)
        reset.tap()
        app.buttons["Cancel"].tap()
        let restraint = app.switches["profile.executiveRestraint"]
        app.swipeDown()
        reveal(restraint, in: app)
        XCTAssertEqual(restraint.value as? String, "1")
        reveal(reset, in: app)
        reset.tap()
        app.buttons["Reset profile"].tap()
        app.terminate()
        app.launch()
        openSettings(in: app)
        reveal(restraint, in: app)
        XCTAssertEqual(restraint.value as? String, "0")
        XCTAssertFalse(app.buttons["onboarding.next"].exists)
    }

    @MainActor
    private func openSettings(in app: XCUIApplication)
    {
        let settings = app.buttons["Settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication)
    {
        for _ in 0 ..< 6
        {
            if element.isHittable
            {
                return
            }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }
}
