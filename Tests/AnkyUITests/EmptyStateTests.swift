// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class EmptyStateTests: XCTestCase {
    func testFirstLaunchShowsEmptyState() {
        continueAfterFailure = false
        let app = launchAnky()

        XCTAssertTrue(app.scrollViews["today-screen"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["today-date"].exists)
        XCTAssertTrue(app.staticTexts["empty-today"].exists)
        XCTAssertEqual(app.cells.count, 0)
        XCTAssertEqual(app.tables.count, 0)

        let logButton = app.buttons["log-entry"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(logButton.frame.height, 44)
        XCTAssertGreaterThan(logButton.frame.width, app.windows.firstMatch.frame.width * 0.8)
        attachScreenshot(named: "empty-state")

        logButton.tap()
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForExistence(timeout: 10))
        let cancel = app.buttons["cancel-entry"]
        XCTAssertTrue(cancel.exists)
        attachScreenshot(named: "new-entry")

        cancel.tap()
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.buttons["log-entry"].exists)
    }
}
