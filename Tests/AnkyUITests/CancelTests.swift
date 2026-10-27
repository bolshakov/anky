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

    func testSwipeDownClosesWhenUnchanged() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        swipeSheetDown(app)

        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertEqual(todayRows(in: app).count, 0)
        attachScreenshot(named: "swipe-down")
    }

    func testSwipeDownIsBlockedAfterChange() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(1, in: app)
        swipeSheetDown(app)

        assertStillOpen(app)
        XCTAssertEqual(app.sliders["severity-slider"].value as? String, "1 of 10")
        XCTAssertEqual(app.alerts.count, 0)
        attachScreenshot(named: "swipe-blocked")

        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(todayRows(in: app).count, 0)
    }

    func testSwipeDownIsBlockedAfterKindChange() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        chooseKind("Stiffness", in: app)
        swipeSheetDown(app)

        assertStillOpen(app)
    }

    func testSwipeDownIsBlockedAfterDateChange() throws {
        continueAfterFailure = false
        let hour = Calendar.current.component(.hour, from: .now)
        try XCTSkipIf(hour < 1, "Moving the hour one back wraps past midnight at 00:xx. Run after 01:00.")
        let app = launchAnky()
        openNewEntry(app)
        showDatePicker(in: app)
        moveHour(by: -1, in: app)
        swipeSheetDown(app)

        assertStillOpen(app)
    }

    func testSwipeDownIsBlockedAfterSeverityChange() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(7, in: app)
        swipeSheetDown(app)

        assertStillOpen(app)
        XCTAssertEqual(app.sliders["severity-slider"].value as? String, "7 of 10")
    }

    func testSwipeDownIsBlockedAfterNoteChange() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        typeNote("Walk note", in: app)
        // The keyboard is up, so a drag leaves the sheet open even when swipes are not blocked.
        // Only the element swipe proves the block.
        app.navigationBars["New Entry"].swipeDown()

        assertStillOpen(app)
    }

    func testSwipeDownIsBlockedAfterNoteOfOnlySpaces() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        typeNote("   ", in: app)
        // The keyboard is up, so a drag leaves the sheet open even when swipes are not blocked.
        // Only the element swipe proves the block.
        app.navigationBars["New Entry"].swipeDown()

        assertStillOpen(app)
    }

    /// A slow drag from the top of the screen. It closes an unchanged sheet when the keyboard is down.
    private func swipeSheetDown(_ app: XCUIApplication) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    /// The sheet is still animating for a moment after a swipe, so a plain `exists` check could pass too early.
    private func assertStillOpen(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(app.staticTexts["New Entry"].waitForNonExistence(timeout: 3), file: file, line: line)
        XCTAssertEqual(app.alerts.count, 0, file: file, line: line)
    }

    private func todayRows(in app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "entry-row")
    }
}
