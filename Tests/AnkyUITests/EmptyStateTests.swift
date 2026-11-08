// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class EmptyStateTests: XCTestCase {
    func testFirstLaunchShowsEmptyState() {
        continueAfterFailure = false
        let app = launchAnky()

        XCTAssertTrue(app.descendants(matching: .any)["today-screen"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["today-date"].exists)
        XCTAssertTrue(app.staticTexts["empty-today"].exists)
        XCTAssertEqual(entryRows(in: app).count, 0)
        XCTAssertFalse(app.staticTexts["Levels are 0 to 10. Everything stays on this iPhone."].exists)

        let logButton = app.buttons["log-entry"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(logButton.frame.height, 44)
        attachScreenshot(named: "empty-state")

        logButton.tap()
        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForExistence(timeout: 10))
        let cancel = app.buttons["cancel-entry"]
        XCTAssertTrue(cancel.exists)
        attachScreenshot(named: "new-entry")

        cancel.tap()
        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.buttons["log-entry"].exists)
    }
}
