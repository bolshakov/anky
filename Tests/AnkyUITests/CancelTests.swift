import XCTest

@MainActor
final class CancelTests: XCTestCase {
    func testCancelUnchangedClosesAtOnce() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(6, in: app)
        saveEntry(app)
        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))

        openNewEntry(app)
        app.buttons["Cancel"].tap()

        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Discard"].exists)
        XCTAssertEqual(todayRows(in: app).count, 1)
        attachScreenshot(named: "cancel-saves-nothing")
    }

    func testCancelAfterChangeClosesAtOnce() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(1, in: app)
        app.buttons["Cancel"].tap()

        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Discard"].exists)
        XCTAssertEqual(todayRows(in: app).count, 0)
        attachScreenshot(named: "cancel-after-change")
    }

    func testSwipeDownClosesAfterChange() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(1, in: app)
        app.navigationBars["New Entry"].swipeDown()

        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertEqual(todayRows(in: app).count, 0)
        attachScreenshot(named: "swipe-down")
    }

    private func todayRows(in app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "entry-row")
    }
}
