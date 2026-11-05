// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// While Log Dose's time is unedited it follows the clock and is timed when the dose is saved. Once the person sets it,
/// it is kept. Each test crosses a minute, since the rule is about which minute the clock is in.
@MainActor
final class LogDoseTimeTests: XCTestCase {
    func testAnUneditedDoseTimeFollowsTheClockAndIsTimedAtSaving() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        let opened = dateRowTime(in: app)
        waitForMinuteToChange(from: opened)
        expectDateRowShowsTheClock(in: app)

        XCTAssertNotEqual(saveDoseTimedNow(in: app), opened)
    }

    func testOpeningAndClosingTheDateWheelLeavesTheTimeUnedited() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        let opened = dateRowTime(in: app)
        openDateWheel(in: app)
        dateRow(in: app).tap()
        XCTAssertTrue(dateWheel(in: app).waitForNonExistence(timeout: 10))

        waitForMinuteToChange(from: opened)
        expectDateRowShowsTheClock(in: app)
        XCTAssertNotEqual(saveDoseTimedNow(in: app), opened)
    }

    func testCancellingNewEntryFromTheRowLeavesNoReadingAndTheTimeUnedited() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        let opened = dateRowTime(in: app)
        openHowYouFeel(app)
        app.buttons["cancel-entry"].tap()
        XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.buttons["log-how-you-feel-row"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["before-reading-row"].exists)

        waitForMinuteToChange(from: opened)
        expectDateRowShowsTheClock(in: app)
        XCTAssertNotEqual(saveDoseTimedNow(in: app), opened)
    }

    /// The person sets the time an hour back, so an entry logged now is later than the dose and is not its reading.
    func testATimeSetByHandIsKeptAndAnEntryLoggedAfterItDoesNotMoveIt() throws {
        continueAfterFailure = false
        let hour = Calendar.current.component(.hour, from: .now)
        try XCTSkipIf(hour < 2, "An hour back falls on the day before before 02:00. Run after 02:00.")
        let app = launchAnky()
        addZorblex(app)
        setDateTimeHoursBack(1, in: app)
        let chosen = dateRowTime(in: app)
        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)

        XCTAssertTrue(app.buttons["log-how-you-feel-row"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["before-reading-row"].exists)
        XCTAssertEqual(saveDose(in: app), chosen)
        XCTAssertFalse(doseRow(in: app).label.contains("of 10"), doseRow(in: app).label)
    }

    /// The reading is the entry the chooser logs, saved a minute after Log Dose opened, and the dose is saved after it.
    func testAnEntryLoggedFromTheChooserBecomesTheReadingAndTheDoseIsLaterThanIt() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        let opened = dateRowTime(in: app)
        waitForMinuteToChange(from: opened)
        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)

        app.buttons["before-reading-row"].tap()
        XCTAssertTrue(app.buttons["reading-cancel"].waitForExistence(timeout: 10))
        let fourOfTen = app.buttons.matching(identifier: "reading-option")
        XCTAssertEqual(fourOfTen.count, 1)
        XCTAssertTrue(readingValue(fourOfTen.element(boundBy: 0)).contains("4 of 10"))
        XCTAssertTrue(fourOfTen.element(boundBy: 0).isSelected)
        app.buttons["reading-log-new"].tap()
        XCTAssertTrue(entryScreen(app).waitForExistence(timeout: 10))
        setSeverity(3, in: app)
        saveEntry(app)
        XCTAssertTrue(app.buttons["reading-cancel"].waitForNonExistence(timeout: 10))

        app.buttons["before-reading-row"].tap()
        XCTAssertTrue(app.buttons["reading-cancel"].waitForExistence(timeout: 10))
        let both = app.buttons.matching(identifier: "reading-option")
        XCTAssertEqual(both.count, 2)
        XCTAssertTrue(readingValue(both.element(boundBy: 0)).contains("3 of 10"))
        XCTAssertTrue(both.element(boundBy: 0).isSelected)
        XCTAssertTrue(readingValue(both.element(boundBy: 1)).contains("4 of 10"))
        app.buttons["reading-cancel"].tap()
        XCTAssertTrue(app.buttons["reading-cancel"].waitForNonExistence(timeout: 10))
        let entered = clockTime(at: .now)

        waitForMinuteToChange(from: entered)
        let before = app.buttons["before-reading-row"]
        XCTAssertTrue(before.waitForExistence(timeout: 10))
        XCTAssertTrue(before.label.contains("3 of 10"), before.label)
        expectDateRowShowsTheClock(in: app)
        let time = saveDoseTimedNow(in: app)
        XCTAssertNotEqual(time, entered)
        XCTAssertTrue(doseRow(in: app).label.contains("Pain was 3 of 10"), doseRow(in: app).label)
    }

    private func readingValue(_ option: XCUIElement) -> String {
        option.value as? String ?? ""
    }

    /// The time the dose row on Today shows, which its spoken label starts with.
    private func doseTime(in app: XCUIApplication) -> String {
        String(doseRow(in: app).label.prefix(while: { $0 != "." }))
    }

    /// Saves the dose and returns the time its row shows.
    private func saveDose(in app: XCUIApplication) -> String {
        app.buttons["save-dose"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
        return doseTime(in: app)
    }

    /// Saves the dose and checks that it took the minute of saving, which is the minute before or after the tap.
    private func saveDoseTimedNow(in app: XCUIApplication) -> String {
        let before = clockTime(at: .now)
        let time = saveDose(in: app)
        XCTAssertTrue([before, clockTime(at: .now)].contains(time), "dose time is \(time)")
        return time
    }

    /// The date row redraws a moment after the minute turns, so this waits for it rather than reading it at once.
    private func expectDateRowShowsTheClock(in app: XCUIApplication) {
        let deadline = Date.now.addingTimeInterval(10)
        while dateRowTime(in: app) != clockTime(at: .now), Date.now < deadline {
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertEqual(dateRowTime(in: app), clockTime(at: .now))
    }

    private func openHowYouFeel(_ app: XCUIApplication) {
        app.buttons["log-how-you-feel-row"].tap()
        XCTAssertTrue(entryScreen(app).waitForExistence(timeout: 10))
    }

    private func saveFourOfTenFromNewEntry(_ app: XCUIApplication) {
        setSeverity(4, in: app)
        saveEntry(app)
        XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))
    }
}
