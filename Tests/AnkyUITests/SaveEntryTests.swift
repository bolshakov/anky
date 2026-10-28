import XCTest

@MainActor
final class SaveEntryTests: XCTestCase {
    func testSaveEntryOnToday() {
        continueAfterFailure = false
        let app = launchAnky()
        let labels = saveFourOfTen(in: app)

        expectOneTodayRow(in: app, labelsForSaveMinute: labels)
        attachScreenshot(named: "save-entry-on-today")
    }

    func testEntrySurvivesRelaunch() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        let labels = saveFourOfTen(in: app)
        app.terminate()

        let relaunched = launchAnky(folder: folder)
        expectOneTodayRow(in: relaunched, labelsForSaveMinute: labels)
        attachScreenshot(named: "entry-survives-relaunch")
    }

    func testEachLaunchStartsWithItsOwnEntries() {
        continueAfterFailure = false
        let app = launchAnky()
        _ = saveFourOfTen(in: app)
        app.terminate()

        let fresh = launchAnky()
        XCTAssertTrue(fresh.staticTexts["empty-today"].waitForExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: fresh).count, 0)
    }

    /// The row's time can fall in the minute before or after the save, so both times are returned.
    private func saveFourOfTen(in app: XCUIApplication) -> [String] {
        let before = timeText(at: .now)
        openNewEntry(app)
        setSeverity(4, in: app)
        saveEntry(app)
        let after = timeText(at: .now)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
        return [before, after]
    }

    private func expectOneTodayRow(in app: XCUIApplication, labelsForSaveMinute labels: [String]) {
        let rows = entryRows(in: app)
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(rows.count, 1)
        let row = rows.firstMatch
        XCTAssertTrue(labels.contains(rowTime(of: row)), "row time is \(rowTime(of: row))")
        XCTAssertEqual(rowSeverity(of: row), 4)
    }

    private func timeText(at date: Date) -> String {
        let style = Date.FormatStyle(date: .omitted, time: .shortened).locale(Locale(identifier: "en_GB"))
        return date.formatted(style)
    }
}
