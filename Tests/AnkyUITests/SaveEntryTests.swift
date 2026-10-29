import XCTest

@MainActor
final class SaveEntryTests: XCTestCase {
    func testSaveEntryOnToday() {
        continueAfterFailure = false
        let app = launchAnky()
        saveFourOfTen(in: app)

        expectOneTodayRow(in: app)
        attachScreenshot(named: "save-entry-on-today")
    }

    func testEntrySurvivesRelaunch() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        saveFourOfTen(in: app)
        app.terminate()

        let relaunched = launchAnky(folder: folder)
        expectOneTodayRow(in: relaunched)
        attachScreenshot(named: "entry-survives-relaunch")
    }

    func testEachLaunchStartsWithItsOwnEntries() {
        continueAfterFailure = false
        let app = launchAnky()
        saveFourOfTen(in: app)
        app.terminate()

        let fresh = launchAnky()
        XCTAssertTrue(fresh.staticTexts["empty-today"].waitForExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: fresh).count, 0)
    }

    /// The time is read from the date row before the save, since the saved row's label has no digits in double-length
    /// text. It falls in the minute before or after the save.
    private func saveFourOfTen(in app: XCUIApplication) {
        let before = timeText(at: .now)
        openNewEntry(app)
        setSeverity(4, in: app)
        let dateRow = app.buttons["date-row"]
        let shown = clockTime(inRowValue: dateRow.value as? String)
        saveEntry(app)
        let after = timeText(at: .now)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
        XCTAssertTrue([before, after].contains(shown ?? ""), "date row time is \(shown ?? "nil")")
    }

    private func expectOneTodayRow(in app: XCUIApplication) {
        let rows = entryRows(in: app)
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rowSeverity(of: rows.firstMatch), 4)
    }

    private func timeText(at date: Date) -> String {
        let style = Date.FormatStyle(date: .omitted, time: .shortened).locale(Locale(identifier: "en_GB"))
        return date.formatted(style)
    }
}
