import XCTest

@MainActor
final class NoFutureTimeTests: XCTestCase {
    func testPickerStopsAtNow() throws {
        continueAfterFailure = false
        let hour = Calendar.current.component(.hour, from: .now)
        try XCTSkipIf(hour >= 23, "Moving the hour one ahead wraps past midnight at \(hour):xx. Run before 23:00.")
        let app = launchAnky()
        let openedAt = Date.now
        openNewEntry(app)
        showDatePicker(in: app)

        moveHour(by: 1, in: app)

        // The picker clamps to the moment it was last drawn, so the row shows the opening minute or the current one.
        let shown = app.buttons["date-row"].value as? String
        XCTAssertTrue([dateRowValue(at: openedAt), dateRowValue(at: .now)].contains(shown))
        attachScreenshot(named: "no-future-time")
    }
}
