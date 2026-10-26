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
        XCTAssertTrue(fresh.staticTexts["Nothing logged today"].waitForExistence(timeout: 10))
        XCTAssertEqual(todayRows(in: fresh).count, 0)
    }

    /// The row's time can fall in the minute before or after the save, so both labels are returned.
    private func saveFourOfTen(in app: XCUIApplication) -> [String] {
        openNewEntry(app)
        setSeverity(4, in: app)
        let before = rowLabel(at: .now)
        saveEntry(app)
        let after = rowLabel(at: .now)
        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))
        return [before, after]
    }

    private func expectOneTodayRow(in app: XCUIApplication, labelsForSaveMinute labels: [String]) {
        let rows = todayRows(in: app)
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(rows.count, 1)
        XCTAssertTrue(labels.contains(rows.firstMatch.label), "row reads \(rows.firstMatch.label)")
    }

    private func todayRows(in app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "entry-row")
    }

    private func rowLabel(at date: Date) -> String {
        let style = Date.FormatStyle(date: .omitted, time: .shortened).locale(Locale(identifier: "en_GB"))
        return "\(date.formatted(style)), Pain, 4 of 10"
    }
}
