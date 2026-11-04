// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class HistoryCheckInTests: XCTestCase {
    func testAWaitingDoseInHistoryOpensCheckInWhileTodayOpensEditDose() throws {
        continueAfterFailure = false
        let hour = Calendar.current.component(.hour, from: .now)
        try XCTSkipIf(hour < 3, "Two hours back falls on hour 00 before 03:00. Run after 03:00.")
        let app = launchAnky()
        addZorblexCheckingInAfterThirtyMinutes(app)
        logZorblexTwoHoursBack(app)

        doseRow(in: app).tap()
        XCTAssertTrue(editDoseScreen(in: app).waitForExistence(timeout: 10))
        app.buttons["edit-dose-cancel"].tap()
        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
        let label = app.descendants(matching: .any)["check-in-label"]
        XCTAssertTrue(label.waitForExistence(timeout: 10))
        XCTAssertEqual(label.label, "Check in")

        doseRow(in: app).tap()
        XCTAssertTrue(app.descendants(matching: .any)["check-in-screen"].waitForExistence(timeout: 10))
        XCTAssertFalse(editDoseScreen(in: app).exists)
    }

    private func addZorblexCheckingInAfterThirtyMinutes(_ app: XCUIApplication) {
        app.buttons["log-medication"].tap()
        app.buttons["dose-add-medication"].tap()
        let name = app.textFields["medication-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Zorblex")
        let checkIn = app.descendants(matching: .any).matching(identifier: "check-in-after").firstMatch
        XCTAssertTrue(checkIn.waitForExistence(timeout: 10))
        let save = app.buttons["medication-save"]
        for _ in 0 ..< 5 where checkIn.frame.maxY > save.frame.minY {
            app.swipeUp()
        }
        checkIn.tap()
        let thirtyMinutes = app.buttons["30 minutes"]
        XCTAssertTrue(thirtyMinutes.waitForExistence(timeout: 10))
        thirtyMinutes.tap()
        save.tap()
        XCTAssertTrue(app.buttons["log-how-you-feel-row"].waitForExistence(timeout: 10))
    }

    private func logZorblexTwoHoursBack(_ app: XCUIApplication) {
        setDateTimeHoursBack(2, in: app)
        app.buttons["save-dose"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
    }

    private func doseRow(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["dose-row"]
    }

    private func editDoseScreen(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["edit-dose-screen"]
    }
}
