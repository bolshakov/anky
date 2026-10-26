import XCTest

@MainActor
final class EmptyStateTests: XCTestCase {
    func testFirstLaunchShowsEmptyState() {
        continueAfterFailure = false
        let app = launchAnky()

        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["today-date"].exists)
        XCTAssertTrue(app.staticTexts["Nothing logged today"].exists)

        let logButton = app.buttons["Log how you feel"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(logButton.frame.height, 44)
        XCTAssertGreaterThan(logButton.frame.width, app.windows.firstMatch.frame.width * 0.8)
        attachScreenshot(named: "empty-state")

        logButton.tap()
        XCTAssertTrue(app.staticTexts["New Entry"].waitForExistence(timeout: 10))
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.exists)
        attachScreenshot(named: "new-entry")

        cancel.tap()
        XCTAssertTrue(app.buttons["Log how you feel"].waitForExistence(timeout: 10))
    }
}
