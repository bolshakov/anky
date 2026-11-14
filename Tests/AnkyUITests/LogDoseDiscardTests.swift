// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class LogDoseDiscardTests: XCTestCase {
    func testLogDoseAfterAChangeAsksOnCancelAndKeepsItselfOnSwipeDown() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        setDateToYesterday(in: app)
        app.buttons["log-dose-cancel"].tap()

        XCTAssertFalse(app.navigationBars["Log Dose"].waitForNonExistence(timeout: 2))
        discardChanges(in: app)
        XCTAssertTrue(app.navigationBars["Log Dose"].waitForNonExistence(timeout: 10))
        assertHistoryIsEmpty(in: app)

        tapLogMedication(in: app)
        setDateToYesterday(in: app)
        swipeSheetDown(app)

        XCTAssertTrue(app.navigationBars["Log Dose"].exists)
        app.buttons["log-dose-cancel"].tap()
        discardChanges(in: app)
        XCTAssertTrue(app.navigationBars["Log Dose"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(app.alerts.count, 0)
        assertHistoryIsEmpty(in: app)
    }

    /// Today lists only the current day, so a dose saved for yesterday shows only in History. The empty state is
    /// the one History shows when nothing is logged.
    private func assertHistoryIsEmpty(in app: XCUIApplication) {
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["empty-history"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Today"].tap()
    }

    func testAFailedDoseSaveKeepsLogDoseOpenWithTheChosenMedication() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        addZorblex(app)
        addMedication("Quibbanol", in: app)
        app.terminate()

        let failing = launchAnky(folder: folder, arguments: ["-ANKY_FAIL_MEDICATION_WRITES", "1"])
        tapLogMedication(in: failing)
        chooseMedication("Quibbanol", in: failing)
        failing.buttons["save-dose"].tap()

        let alert = failing.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertEqual(alert.label, "Couldn't save this dose. Try again.")
        XCTAssertEqual(alert.buttons.count, 1)
        alert.buttons["OK"].tap()

        XCTAssertTrue(failing.navigationBars["Log Dose"].waitForExistence(timeout: 10))
        XCTAssertEqual(selectedMedication(in: failing), "Quibbanol")
        XCTAssertTrue(failing.buttons["save-dose"].isEnabled)

        failing.buttons["save-dose"].tap()

        XCTAssertTrue(doseRow(in: failing).waitForExistence(timeout: 10))
        XCTAssertTrue(doseRow(in: failing).label.contains("Quibbanol"), doseRow(in: failing).label)
    }
}
