// SPDX-License-Identifier: GPL-3.0-or-later
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

    private func expectOneTodayRow(in app: XCUIApplication) {
        let rows = entryRows(in: app)
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rowSeverity(of: rows.firstMatch), 4)
    }
}
