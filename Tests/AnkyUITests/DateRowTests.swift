// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class DateRowTests: XCTestCase {
    func testRowShowsTodayAndTogglesThePicker() {
        continueAfterFailure = false
        let app = launchAnky()
        let shownBefore = clockTime(at: .now)
        openNewEntry(app)

        let row = dateRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(row.label, "Date and time")
        let spoken = row.value as? String ?? ""
        XCTAssertTrue(
            ["Today \(shownBefore)", "Today \(clockTime(at: .now))"].contains(spoken),
            "date row is \(spoken)"
        )
        XCTAssertFalse(dateWheel(in: app).exists)

        openDateWheel(in: app)
        row.tap()
        XCTAssertTrue(dateWheel(in: app).waitForNonExistence(timeout: 10))
    }

    func testNewEntryRowOpensThePickerFromItsTopAndLeadingEdges() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        tapDateRowEdge(in: app, dx: 0.03, dy: 0.5)
        XCTAssertTrue(dateWheel(in: app).waitForExistence(timeout: 10))
    }

    func testNewEntryRowOpensThePickerFromItsTopEdge() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        tapDateRowEdge(in: app, dx: 0.5, dy: 0.1)
        XCTAssertTrue(dateWheel(in: app).waitForExistence(timeout: 10))
    }

    func testLogDoseRowOpensThePickerFromItsEdges() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()

        tapDateRowEdge(in: app, dx: 0.03, dy: 0.5)
        XCTAssertTrue(dateWheel(in: app).waitForExistence(timeout: 10))
    }

    func testLogDoseWheelOpensSixteenPointsBelowTheDateText() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        openDateWheel(in: app)

        let text = app.staticTexts["Date and time"].firstMatch
        let wheel = dateWheel(in: app)
        XCTAssertEqual(wheel.frame.minY - text.frame.maxY, 16, accuracy: 1)
    }

    private func tapDateRowEdge(in app: XCUIApplication, dx: CGFloat, dy: CGFloat) {
        let cell = dateRowCell(in: app)
        XCTAssertTrue(cell.waitForExistence(timeout: 10))
        cell.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy)).tap()
    }
}
