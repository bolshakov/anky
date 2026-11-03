// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class LogDoseDiscardTests: XCTestCase {
    func testLogDoseCancelAndSwipeDownSaveNothing() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        moveToYesterday(in: app)
        app.buttons["log-dose-cancel"].tap()

        XCTAssertTrue(app.navigationBars["Log Dose"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertFalse(doseRow(in: app).exists)

        tapLogMedication(in: app)
        moveToYesterday(in: app)
        swipeSheetDown(app)

        XCTAssertTrue(app.navigationBars["Log Dose"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertFalse(doseRow(in: app).exists)
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
        XCTAssertEqual(alert.label, "This dose could not be saved.")
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
