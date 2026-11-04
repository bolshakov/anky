// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class TodayDeleteSwipeTests: XCTestCase {
    func testAPartSwipeOnATodayEntryShowsDeleteAndOpensNoEditor() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        partSwipeRow(row)

        XCTAssertTrue(app.buttons["history-delete"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["confirm-delete"].firstMatch.exists)
        XCTAssertFalse(identified("edit-entry-screen", in: app).exists)
        XCTAssertEqual(entryRows(in: app).count, 1)
    }

    func testAPartSwipeOnATodayDoseShowsDeleteAndOpensNoEditor() {
        continueAfterFailure = false
        let app = launchAnky()
        logZorblexDose(in: app)

        let row = doseRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        partSwipeRow(row)

        XCTAssertTrue(app.buttons["history-delete"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["confirm-delete"].firstMatch.exists)
        XCTAssertFalse(editDoseScreen(in: app).exists)
        XCTAssertTrue(row.exists)
    }

    func testTheEntryDeleteAlertFromTodayAsksInTheEntryWords() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        tapDeleteOnRow(row, in: app)

        let alert = app.alerts["Delete this entry? This can't be undone."].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertEqual(alert.buttons["confirm-delete"].firstMatch.label, "Delete entry")
        alert.buttons["keep-entry"].firstMatch.tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 1)
    }

    func testTheDoseDeleteAlertFromTodayAsksInTheDoseWords() {
        continueAfterFailure = false
        let app = launchAnky()
        logZorblexDose(in: app)

        let row = doseRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        tapDeleteOnRow(row, in: app)

        let alert = app.alerts["Delete this dose? This can't be undone."].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertEqual(alert.buttons["confirm-delete"].firstMatch.label, "Delete dose")
        alert.buttons["keep-entry"].firstMatch.tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 10))
        XCTAssertTrue(row.waitForExistence(timeout: 10))
    }

    func testAFullSwipeOnATodayEntryAsksAndKeepKeepsIt() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        fullSwipeRow(row)
        XCTAssertTrue(app.buttons["confirm-delete"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["keep-entry"].firstMatch.tap()
        XCTAssertTrue(app.buttons["keep-entry"].firstMatch.waitForNonExistence(timeout: 10))

        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 1)
    }

    func testAFullSwipeOnATodayEntryThenConfirmRemovesIt() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        fullSwipeRow(row)
        app.buttons["confirm-delete"].firstMatch.tap()

        XCTAssertTrue(row.waitForNonExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 0)
    }

    func testAFullSwipeOnATodayDoseAsksAndKeepKeepsIt() {
        continueAfterFailure = false
        let app = launchAnky()
        logZorblexDose(in: app)

        let row = doseRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        fullSwipeRow(row)
        XCTAssertTrue(app.buttons["confirm-delete"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["keep-entry"].firstMatch.tap()
        XCTAssertTrue(app.buttons["keep-entry"].firstMatch.waitForNonExistence(timeout: 10))

        XCTAssertTrue(row.waitForExistence(timeout: 10))
    }

    func testAFullSwipeOnATodayDoseThenConfirmRemovesIt() {
        continueAfterFailure = false
        let app = launchAnky()
        logZorblexDose(in: app)

        let row = doseRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        fullSwipeRow(row)
        app.buttons["confirm-delete"].firstMatch.tap()

        XCTAssertTrue(row.waitForNonExistence(timeout: 10))
    }

    /// The Logged card names the newest entry, which is the first row, so swiping that row removes the card with it.
    func testSwipeDeletingTheJustLoggedEntryTakesItsLoggedCard() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        let chip = app.buttons["repeat-chip"]
        XCTAssertTrue(chip.waitForExistence(timeout: 10))
        chip.tap()
        XCTAssertTrue(identified("repeat-logged", in: app).waitForExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 2)

        fullSwipeRow(entryRows(in: app).firstMatch)
        app.buttons["confirm-delete"].firstMatch.tap()

        XCTAssertTrue(app.buttons["repeat-chip"].waitForExistence(timeout: 10))
        XCTAssertFalse(identified("repeat-logged", in: app).exists)
        XCTAssertFalse(app.buttons["repeat-undo"].exists)
        XCTAssertEqual(entryRows(in: app).count, 1)
    }

    func testSwipeDeletingAWaitingDoseOnTodayRemovesItsCheckIn() throws {
        continueAfterFailure = false
        let hour = Calendar.current.component(.hour, from: .now)
        try XCTSkipIf(hour < 3, "Two hours back falls on hour 00 before 03:00. Run after 03:00.")
        let app = launchAnky()
        addZorblexWithAThirtyMinuteCheckIn(app)
        setDateTimeHoursBack(2, in: app)
        app.buttons["save-dose"].tap()

        let row = doseRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(identified("check-in-row", in: app).waitForExistence(timeout: 10))
        fullSwipeRow(row)
        app.buttons["confirm-delete"].firstMatch.tap()

        XCTAssertTrue(row.waitForNonExistence(timeout: 10))
        XCTAssertTrue(identified("check-in-row", in: app).waitForNonExistence(timeout: 10))
    }

    private func logZorblexDose(in app: XCUIApplication) {
        addZorblex(app)
        app.buttons["save-dose"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
    }

    private func addZorblexWithAThirtyMinuteCheckIn(_ app: XCUIApplication) {
        app.buttons["log-medication"].tap()
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
