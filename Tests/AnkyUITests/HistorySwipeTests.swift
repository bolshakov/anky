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
        XCTAssertTrue(app.buttons["history-delete"].firstMatch.waitForNonExistence(timeout: 10))

        XCTAssertEqual(entryRows(in: app).count, 1)
        partSwipeRow(row)
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

    func testAFullSwipeOnAnEntryRowAsksToDeleteAndKeepKeepsTheEntry() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        showHistory(in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        fullSwipeRow(row)
        XCTAssertTrue(app.buttons["confirm-delete"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["keep-entry"].firstMatch.tap()
        XCTAssertTrue(app.buttons["keep-entry"].firstMatch.waitForNonExistence(timeout: 10))

        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 1)
    }

    func testAFullSwipeOnAnEntryRowThenConfirmRemovesTheEntry() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        showHistory(in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        fullSwipeRow(row)
        app.buttons["confirm-delete"].firstMatch.tap()

        XCTAssertTrue(row.waitForNonExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 0)
    }

    func testAPartSwipeOnADoseRowShowsDeleteAndAsksNothing() {
        continueAfterFailure = false
        let app = launchAnky()
        logZorblexDose(in: app)
        showHistory(in: app)

        let row = doseRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        partSwipeRow(row)
        XCTAssertTrue(app.buttons["history-delete"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["confirm-delete"].firstMatch.exists)
        XCTAssertTrue(row.exists)
    }

    func testAFullSwipeOnADoseRowAsksToDeleteAndKeepKeepsTheDose() {
        continueAfterFailure = false
        let app = launchAnky()
        logZorblexDose(in: app)
        showHistory(in: app)

        let row = doseRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        fullSwipeRow(row)
        XCTAssertTrue(app.buttons["confirm-delete"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["keep-entry"].firstMatch.tap()
        XCTAssertTrue(app.buttons["keep-entry"].firstMatch.waitForNonExistence(timeout: 10))

        XCTAssertTrue(row.waitForExistence(timeout: 10))
    }

    func testAFullSwipeOnADoseRowThenConfirmRemovesTheDose() {
        continueAfterFailure = false
        let app = launchAnky()
        logZorblexDose(in: app)
        showHistory(in: app)

        let row = doseRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        fullSwipeRow(row)
        app.buttons["confirm-delete"].firstMatch.tap()

        XCTAssertTrue(row.waitForNonExistence(timeout: 10))
    }

    func testAFullSwipeOnAWaitingDoseAsksToDelete() throws {
        continueAfterFailure = false
        let hour = Calendar.current.component(.hour, from: .now)
        try XCTSkipIf(hour < 3, "Two hours back falls on hour 00 before 03:00. Run after 03:00.")
        let app = launchAnky()
        addZorblexWithAThirtyMinuteCheckIn(app)
        setDateTimeHoursBack(2, in: app)
        app.buttons["save-dose"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
        showHistory(in: app)
        XCTAssertTrue(identified("check-in-label", in: app).waitForExistence(timeout: 10))

        let row = doseRow(in: app)
        fullSwipeRow(row)
        XCTAssertTrue(app.buttons["confirm-delete"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["keep-entry"].firstMatch.tap()
        XCTAssertTrue(app.buttons["keep-entry"].firstMatch.waitForNonExistence(timeout: 10))
        XCTAssertTrue(row.waitForExistence(timeout: 10))
    }

    func testTheEntryDeleteAlertFromHistoryAsksInTheEntryWords() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        showHistory(in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        tapDeleteOnRow(row, in: app)

        let alert = app.alerts["Delete this entry? This can't be undone."].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertEqual(alert.buttons["confirm-delete"].firstMatch.label, "Delete entry")
        alert.buttons["keep-entry"].firstMatch.tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 10))
    }

    private func logZorblexDose(in app: XCUIApplication) {
        addZorblex(app)
        app.buttons["save-dose"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
    }

    private func addZorblexWithAThirtyMinuteCheckIn(_ app: XCUIApplication) {
        tapLogMedication(in: app)
        app.buttons["dose-add-medication"].tap()
        let name = app.textFields["medication-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Zorblex")
        app.typeText("\n")
        app.typeText("\n")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 10))
        let form = app.descendants(matching: .any).matching(identifier: "medication-form").firstMatch
        let toggle = form.descendants(matching: .any).matching(identifier: "check-in-later").firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let save = app.buttons["medication-save"]
        for _ in 0 ..< 5 where toggle.frame.maxY > save.frame.minY {
            app.swipeUp()
        }
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        let menu = form.descendants(matching: .any).matching(identifier: "dose-check-in-after").firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        for _ in 0 ..< 5 where menu.frame.maxY > save.frame.minY {
            app.swipeUp()
        }
        menu.tap()
        let thirtyMinutes = app.buttons["30 minutes"]
        XCTAssertTrue(thirtyMinutes.waitForExistence(timeout: 10))
        thirtyMinutes.tap()
        save.tap()
        XCTAssertTrue(app.buttons["log-how-you-feel-row"].waitForExistence(timeout: 10))
    }
}
