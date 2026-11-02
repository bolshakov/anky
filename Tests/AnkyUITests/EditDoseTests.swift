// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class EditDoseTests: XCTestCase {
    func testADoseRowOnTodayOpensEditDose() {
        continueAfterFailure = false
        let app = launchAnky()
        logZorblexDose(app)

        doseRow(in: app).tap()

        XCTAssertTrue(editDoseScreen(in: app).waitForExistence(timeout: 10))
    }

    func testADoseRowInHistoryOpensEditDose() {
        continueAfterFailure = false
        let app = launchAnky()
        logZorblexDose(app)

        app.tabBars.buttons["History"].tap()
        doseRow(in: app).tap()

        XCTAssertTrue(editDoseScreen(in: app).waitForExistence(timeout: 10))
    }

    /// The dose keeps the id of its before-entry after that entry is deleted, so Edit Dose reads it as None.
    func testADeletedBeforeEntryShowsNoneAndOpensNothing() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        logFourOfTenBeforeTheDose(app)
        let logged = app.buttons["before-reading-row"]
        XCTAssertTrue(logged.waitForExistence(timeout: 10))
        XCTAssertTrue(logged.label.contains("4 of 10"), logged.label)
        app.buttons["save-dose"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))

        doseRow(in: app).tap()
        let linked = app.buttons["before-reading-row"]
        XCTAssertTrue(linked.waitForExistence(timeout: 10))
        XCTAssertTrue(linked.label.contains("4 of 10"), linked.label)
        app.buttons["edit-dose-cancel"].tap()
        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))

        deleteTodaysPainEntry(in: app)
        doseRow(in: app).tap()

        let before = app.descendants(matching: .any)["before-reading-row"]
        XCTAssertTrue(before.waitForExistence(timeout: 10))
        XCTAssertTrue(before.label.contains("None"), before.label)
        XCTAssertFalse(app.buttons["before-reading-row"].exists)

        before.tap()
        XCTAssertFalse(app.descendants(matching: .any)["edit-entry-screen"].exists)
        XCTAssertTrue(editDoseScreen(in: app).exists)
    }

    private func logZorblexDose(_ app: XCUIApplication) {
        addZorblex(app)
        app.buttons["save-dose"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
    }

    /// Leaves Log Dose open with its medication chosen.
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

    private func logFourOfTenBeforeTheDose(_ app: XCUIApplication) {
        app.buttons["log-how-you-feel-row"].tap()
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForExistence(timeout: 10))
        setSeverity(4, in: app)
        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
    }

    private func deleteTodaysPainEntry(in app: XCUIApplication) {
        let painRow = app.descendants(matching: .any)["entry-row-pain"]
        XCTAssertTrue(painRow.waitForExistence(timeout: 10))
        painRow.tap()
        let delete = app.buttons["delete-entry"]
        XCTAssertTrue(delete.waitForExistence(timeout: 10))
        delete.tap()
        app.buttons["confirm-delete"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["edit-entry-screen"].waitForNonExistence(timeout: 10))
    }

    private func doseRow(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["dose-row"]
    }

    private func editDoseScreen(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["edit-dose-screen"]
    }
}
