// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class DateRowTests: XCTestCase {
    func testRowIsTheSystemPickerLabelledDateAndTimeShowingNow() {
        continueAfterFailure = false
        let app = launchAnky()
        let shownBefore = clockTime(at: .now)
        openNewEntry(app)

        let row = dateRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(row.staticTexts["Date and time"].exists)
        XCTAssertTrue(row.datePickers.firstMatch.exists)
        XCTAssertEqual(dateRowDay(in: app), dateRowDate(for: .now))
        let shown = dateRowTime(in: app) ?? ""
        XCTAssertTrue([shownBefore, clockTime(at: .now)].contains(shown), "date row time is \(shown)")
    }
}
