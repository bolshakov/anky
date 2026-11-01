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
}
