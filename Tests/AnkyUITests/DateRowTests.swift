// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class DateRowTests: XCTestCase {
    func testRowShowsTodayAndTogglesThePicker() {
        continueAfterFailure = false
        let app = launchAnky()
        let shownBefore = clockTime(at: .now)
        openNewEntry(app)

        let row = app.buttons["date-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(row.label, "Date and time")
        let spoken = row.value as? String ?? ""
        XCTAssertTrue(
            ["Today \(shownBefore)", "Today \(clockTime(at: .now))"].contains(spoken),
            "date-row is \(spoken)"
        )
        XCTAssertFalse(app.datePickers["date-picker"].exists)

        showDatePicker(in: app)
        row.tap()
        XCTAssertTrue(app.datePickers["date-picker"].waitForNonExistence(timeout: 10))
    }

    func testNewEntryRowOpensThePickerFromItsTopAndLeadingEdges() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        tapDateRowEdge(in: app, dx: 0.03, dy: 0.5)
        XCTAssertTrue(app.datePickers["date-picker"].waitForExistence(timeout: 10))
    }

    func testNewEntryRowOpensThePickerFromItsTopEdge() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        tapDateRowEdge(in: app, dx: 0.5, dy: 0.1)
        XCTAssertTrue(app.datePickers["date-picker"].waitForExistence(timeout: 10))
    }

    func testLogDoseRowOpensThePickerFromItsEdges() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()

        tapDateRowEdge(in: app, dx: 0.03, dy: 0.5)
        XCTAssertTrue(app.datePickers["date-picker"].waitForExistence(timeout: 10))
    }

    func testLogDoseWheelOpensSixteenPointsBelowTheDateText() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        showDatePicker(in: app)

        let text = app.staticTexts["Date and time"].firstMatch
        let wheel = app.datePickers["date-picker"]
        XCTAssertEqual(wheel.frame.minY - text.frame.maxY, 16, accuracy: 1)
    }

    private func tapDateRowEdge(in app: XCUIApplication, dx: CGFloat, dy: CGFloat) {
        let cell = app.cells.containing(.button, identifier: "date-row").firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 10))
        cell.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy)).tap()
    }
}
