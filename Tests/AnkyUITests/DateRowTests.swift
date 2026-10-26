import XCTest

@MainActor
final class DateRowTests: XCTestCase {
    func testRowShowsTodayAndTogglesThePicker() {
        continueAfterFailure = false
        let app = launchAnky()
        let shownBefore = dateRowValue(at: .now)
        openNewEntry(app)

        let row = app.buttons["date-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(row.label, "Date and time")
        XCTAssertTrue([shownBefore, dateRowValue(at: .now)].contains(row.value as? String ?? ""))
        XCTAssertFalse(app.datePickers["date-picker"].exists)

        showDatePicker(in: app)
        row.tap()
        XCTAssertTrue(app.datePickers["date-picker"].waitForNonExistence(timeout: 10))
    }
}
