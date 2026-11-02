// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class LogDoseReadingTests: XCTestCase {
    func testEntrySavedFromLogHowYouFeelBecomesTheBeforeReading() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)

        expectBeforeReadingShowsFourOfTen(app)
    }

    /// The New Entry draft starts when it opens, which can be a minute after the dose time Log Dose fixed on opening.
    /// The test above can finish inside that minute, so this one waits for the minute to roll over first.
    func testEntrySavedInALaterMinuteStillBecomesTheBeforeReading() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        let opened = clockTime(inRowValue: app.buttons["date-row"].value as? String)
        waitForMinuteToChange(from: opened)

        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)
        expectBeforeReadingShowsFourOfTen(app)
    }

    func testChooserListsTheReadingsAndOffersNoNoneChoice() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)

        app.buttons["before-reading-row"].tap()
        XCTAssertTrue(app.buttons["reading-cancel"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "reading-option").count, 1)
        XCTAssertTrue(app.buttons["reading-log-new"].exists)
        XCTAssertFalse(app.buttons["None"].exists)
    }

    func testLogHowYouFeelNowFromTheChooserSelectsTheSavedEntry() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)

        app.buttons["before-reading-row"].tap()
        XCTAssertTrue(app.buttons["reading-log-new"].waitForExistence(timeout: 10))
        app.buttons["reading-log-new"].tap()
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForExistence(timeout: 10))
        setSeverity(3, in: app)
        saveEntry(app)

        XCTAssertTrue(app.buttons["reading-cancel"].waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
        let before = app.buttons["before-reading-row"]
        XCTAssertTrue(before.label.contains("3 of 10"), before.label)
    }

    /// Leaves Log Dose showing its "Log how you feel" row.
    private func addZorblex(_ app: XCUIApplication) {
        app.buttons["log-medication"].tap()
        app.buttons["dose-add-medication"].tap()
        let name = app.textFields["medication-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Zorblex")
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.buttons["log-how-you-feel-row"].waitForExistence(timeout: 10))
    }

    private func openHowYouFeel(_ app: XCUIApplication) {
        app.buttons["log-how-you-feel-row"].tap()
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForExistence(timeout: 10))
    }

    private func saveFourOfTenFromNewEntry(_ app: XCUIApplication) {
        setSeverity(4, in: app)
        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
    }

    private func expectBeforeReadingShowsFourOfTen(_ app: XCUIApplication) {
        let before = app.buttons["before-reading-row"]
        XCTAssertTrue(before.waitForExistence(timeout: 10))
        XCTAssertTrue(before.label.contains("Pain"), before.label)
        XCTAssertTrue(before.label.contains("4 of 10"), before.label)
        XCTAssertFalse(app.buttons["log-how-you-feel-row"].exists)
    }

    private func waitForMinuteToChange(from minute: String?) {
        let deadline = Date.now.addingTimeInterval(90)
        while clockTime(at: .now) == minute, Date.now < deadline {
            Thread.sleep(forTimeInterval: 1)
        }
        XCTAssertNotEqual(clockTime(at: .now), minute)
    }
}
