// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class LogDoseReadingTests: XCTestCase {
    func testEntrySavedFromLogHowYouFeelBecomesTheBeforeReading() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        app.buttons["dose-add-medication"].tap()
        let name = app.textFields["medication-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Zorblex")
        app.buttons["medication-save"].tap()

        let howYouFeel = app.buttons["log-how-you-feel-row"]
        XCTAssertTrue(howYouFeel.waitForExistence(timeout: 10))
        howYouFeel.tap()
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForExistence(timeout: 10))
        setSeverity(4, in: app)
        saveEntry(app)

        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
        let before = app.buttons["before-reading-row"]
        XCTAssertTrue(before.waitForExistence(timeout: 10))
        XCTAssertTrue(before.label.contains("Pain"), before.label)
        XCTAssertTrue(before.label.contains("4 of 10"), before.label)
        XCTAssertFalse(app.buttons["log-how-you-feel-row"].exists)
    }
}
