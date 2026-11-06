// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class HistoryCheckInTests: XCTestCase {
    func testAWaitingDoseShowsCheckInLabelAndOpensCheckInOnTodayAndInHistory() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.pain, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))

        assertWaitingDoseOpensCheckIn(in: app)

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
        assertWaitingDoseOpensCheckIn(in: app)
    }

    private func assertWaitingDoseOpensCheckIn(in app: XCUIApplication) {
        let label = app.descendants(matching: .any)["check-in-label"]
        XCTAssertTrue(label.waitForExistence(timeout: 10))
        XCTAssertEqual(label.label, "Check in")

        doseRow(in: app).tap()
        XCTAssertTrue(app.descendants(matching: .any)["check-in-screen"].waitForExistence(timeout: 10))
        XCTAssertFalse(editDoseScreen(in: app).exists)
        app.buttons["check-in-cancel"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["check-in-screen"].waitForNonExistence(timeout: 10))
    }

    private func doseRow(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["dose-row"]
    }

    private func editDoseScreen(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["edit-dose-screen"]
    }
}
