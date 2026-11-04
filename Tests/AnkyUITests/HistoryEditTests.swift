// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class HistoryEditTests: XCTestCase {
    func testSavingAnEntryAsYesterdayMovesItsRowIntoTheYesterdaySection() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        showHistory(in: app)

        entryRows(in: app).firstMatch.tap()
        XCTAssertTrue(app.buttons["save-entry"].waitForExistence(timeout: 10))
        setDateToYesterday(in: app)
        saveEntry(app)
        XCTAssertTrue(app.buttons["save-entry"].waitForNonExistence(timeout: 10))

        XCTAssertEqual(dayHeaderLabels(in: app), ["Yesterday"])
        let header = app.descendants(matching: .any).matching(identifier: "day-header").firstMatch
        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(row.frame.minY, header.frame.minY)
    }
}
