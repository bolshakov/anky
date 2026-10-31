// SPDX-License-Identifier: GPL-3.0-or-later
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
        let dateRow = app.buttons["date-row"]
        let shown = clockTime(inRowValue: dateRow.value as? String)
        XCTAssertTrue([clockTime(at: openedAt), clockTime(at: .now)].contains(shown))
        attachScreenshot(named: "no-future-time")
    }
}
