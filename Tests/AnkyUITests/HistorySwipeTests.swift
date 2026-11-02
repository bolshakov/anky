// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class HistorySwipeTests: XCTestCase {
    func testCancelKeepsTheRowAndTheSecondSwipeShowsDelete() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        showHistory(in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        tapDeleteOnRow(row, in: app)
        let keep = app.buttons["keep-entry"].firstMatch
        XCTAssertTrue(keep.waitForExistence(timeout: 10))
        keep.tap()
        XCTAssertTrue(app.buttons["keep-entry"].firstMatch.waitForNonExistence(timeout: 10))

        XCTAssertEqual(entryRows(in: app).count, 1)
        row.swipeLeft()
        XCTAssertTrue(app.buttons["history-delete"].firstMatch.waitForExistence(timeout: 10))
    }

    func testDeletingTheOnlyEntryOfADayRemovesItsSection() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        logEntry(6, yesterday: true, in: app)
        showHistory(in: app)
        XCTAssertEqual(dayHeaderLabels(in: app), ["Today", "Yesterday"])

        let yesterdayRow = entryRows(in: app).matching(NSPredicate(format: "label CONTAINS %@", ", 6 of 10")).firstMatch
        XCTAssertTrue(yesterdayRow.waitForExistence(timeout: 10))
        tapDeleteOnRow(yesterdayRow, in: app)
        app.buttons["confirm-delete"].firstMatch.tap()

        XCTAssertTrue(yesterdayRow.waitForNonExistence(timeout: 10))
        XCTAssertEqual(dayHeaderLabels(in: app), ["Today"])
        XCTAssertEqual(entryRows(in: app).count, 1)
    }

    func testDeletingTheLastEntryShowsEmptyHistory() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        showHistory(in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        tapDeleteOnRow(row, in: app)
        app.buttons["confirm-delete"].firstMatch.tap()

        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "empty-history").firstMatch
            .waitForExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 0)
    }
}
