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

    func testCancelAsksAfterChange() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        stepSeverityUpFromZero(in: app)
        app.buttons["Cancel"].tap()

        XCTAssertTrue(app.buttons["Discard"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Keep editing"].exists)
        attachScreenshot(named: "cancel-asks")

        app.buttons["Keep editing"].tap()
        XCTAssertTrue(app.buttons["Discard"].waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["New Entry"].exists)
        XCTAssertEqual(app.sliders["severity-slider"].value as? String, "1 of 10")
        attachScreenshot(named: "cancel-kept")

        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Discard"].waitForExistence(timeout: 10))
        app.buttons["Discard"].tap()

        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Nothing logged today"].waitForExistence(timeout: 10))
        XCTAssertEqual(todayRows(in: app).count, 0)
        attachScreenshot(named: "cancel-discarded")
    }

    func testEveryFieldCountsAsChange() throws {
        continueAfterFailure = false
        let hour = Calendar.current.component(.hour, from: .now)
        try XCTSkipIf(hour < 1, "Moving the hour one back wraps past midnight at 00:xx. Run after 01:00.")
        let app = launchAnky()

        openNewEntry(app)
        chooseKind("Stiffness", in: app)
        expectQuestionThenDiscard(in: app)

        openNewEntry(app)
        typeNote("Walk note", in: app)
        expectQuestionThenDiscard(in: app)

        openNewEntry(app)
        showDatePicker(in: app)
        moveHour(by: -1, in: app)
        expectQuestionThenDiscard(in: app)
    }

    private func expectQuestionThenDiscard(in app: XCUIApplication) {
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Discard"].waitForExistence(timeout: 10))
        app.buttons["Discard"].tap()
        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))
    }

    /// On this slider `adjust` reads 0.05 as 0 and 0.07 as 1, so 0.07 is the position that lands on the first step.
    private func stepSeverityUpFromZero(in app: XCUIApplication) {
        let slider = app.sliders["severity-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        slider.adjust(toNormalizedSliderPosition: 0.07)
        XCTAssertEqual(slider.value as? String, "1 of 10")
    }

    private func todayRows(in app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "entry-row")
    }
}
