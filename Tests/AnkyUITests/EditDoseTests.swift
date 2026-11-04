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
        let rowLabel = doseRow(in: app).label
        doseRow(in: app).tap()

        XCTAssertTrue(editDoseScreen(in: app).waitForExistence(timeout: 10))
        XCTAssertEqual(selectedMedication(in: app), "Zorblex")
        let rowTime = String(rowLabel.prefix(while: { $0 != "." }))
        XCTAssertEqual(dateRowTime(in: app), rowTime, rowLabel)
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

    func testADoseRowOpensEditDoseWithItsMedicationTimeAndReading() throws {
        continueAfterFailure = false
        let app = launchAnky()
        try logZorblexDoseCheckingInLater(app)

        let rowLabel = doseRow(in: app).label
        doseRow(in: app).tap()

        XCTAssertTrue(editDoseScreen(in: app).waitForExistence(timeout: 10))
        XCTAssertEqual(medicationRows(in: app).count, 2)
        XCTAssertEqual(selectedMedication(in: app), "Zorblex")
        let day = dateRowDay(in: app) ?? ""
        XCTAssertTrue(day.hasPrefix("Today"), "date row day is \(day)")
        let rowTime = String(rowLabel.prefix(while: { $0 != "." }))
        XCTAssertEqual(dateRowTime(in: app), rowTime, rowLabel)
        let before = app.buttons["before-reading-row"]
        XCTAssertTrue(before.waitForExistence(timeout: 10))
        XCTAssertTrue(before.label.hasPrefix("Before this dose"), before.label)
        XCTAssertTrue(before.label.contains("4 of 10"), before.label)
        XCTAssertTrue(app.buttons["save-dose-changes"].exists)
        XCTAssertTrue(app.buttons["edit-dose-cancel"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["log-dose-manage"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["dose-add-medication"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["check-in-later"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["dose-check-in-after"].exists)
        attachScreenshot(named: "edit-dose")
    }

    func testCancelAndSwipeDownLeaveTheDoseAsItWas() throws {
        continueAfterFailure = false
        let app = launchAnky()
        try logZorblexDoseCheckingInLater(app)
        let label = doseRow(in: app).label

        doseRow(in: app).tap()
        chooseMedication("Quibbanol", in: app)
        setDateToYesterday(in: app)
        app.buttons["edit-dose-cancel"].tap()

        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))
        assertDoseUnchanged(label, in: app)

        doseRow(in: app).tap()
        chooseMedication("Quibbanol", in: app)
        setDateToYesterday(in: app)
        swipeSheetDown(app)

        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))
        assertDoseUnchanged(label, in: app)
    }

    func testSaveChangesWithAnotherMedicationKeepsTheReadingAndTheDelay() throws {
        continueAfterFailure = false
        let app = launchAnky()
        try logZorblexDoseCheckingInLater(app)

        doseRow(in: app).tap()
        chooseMedication("Quibbanol", in: app)
        app.buttons["save-dose-changes"].tap()

        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(doseRow(in: app).label.contains("Quibbanol"), doseRow(in: app).label)
        XCTAssertTrue(doseRow(in: app).label.contains("4 of 10"), doseRow(in: app).label)
        XCTAssertTrue(checkInRow(in: app).waitForExistence(timeout: 10), "the dose lost its check-in delay")
    }

    func testAMovedDoseShowsUnderYesterdayInHistory() throws {
        continueAfterFailure = false
        let app = launchAnky()
        try logZorblexDoseCheckingInLater(app)

        doseRow(in: app).tap()
        setDateToYesterday(in: app)
        app.buttons["save-dose-changes"].tap()

        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))
        XCTAssertTrue(doseRow(in: app).waitForNonExistence(timeout: 10))
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
        let yesterday = try XCTUnwrap(
            app.descendants(matching: .any).matching(identifier: "day-header")
                .allElementsBoundByIndex.first { $0.label == "Yesterday" },
            "headers are \(dayHeaderLabels(in: app))"
        )
        XCTAssertGreaterThan(doseRow(in: app).frame.minY, yesterday.frame.minY)
        XCTAssertTrue(doseRow(in: app).label.contains("4 of 10"), doseRow(in: app).label)
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(checkInRow(in: app).waitForExistence(timeout: 10), "the dose lost its check-in delay")
    }

    func testAFailedSaveKeepsEditDoseOpenOnTheChosenMedication() throws {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        try logZorblexDoseCheckingInLater(app)
        app.terminate()

        let failing = launchAnky(folder: folder, arguments: ["-ANKY_FAIL_MEDICATION_WRITES", "1"])
        XCTAssertTrue(doseRow(in: failing).waitForExistence(timeout: 10))
        let original = doseRow(in: failing).label
        doseRow(in: failing).tap()
        chooseMedication("Quibbanol", in: failing)
        failing.buttons["save-dose-changes"].tap()

        let alert = failing.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertEqual(alert.label, "This dose could not be saved.")
        XCTAssertEqual(alert.buttons.count, 1)
        alert.buttons["OK"].tap()
        XCTAssertTrue(editDoseScreen(in: failing).waitForExistence(timeout: 10))
        XCTAssertEqual(selectedMedication(in: failing), "Quibbanol")
        XCTAssertTrue(failing.buttons["save-dose-changes"].isEnabled)

        failing.buttons["edit-dose-cancel"].tap()
        XCTAssertTrue(editDoseScreen(in: failing).waitForNonExistence(timeout: 10))
        assertDoseUnchanged(original, in: failing)

        doseRow(in: failing).tap()
        chooseMedication("Quibbanol", in: failing)
        failing.buttons["save-dose-changes"].tap()

        XCTAssertTrue(editDoseScreen(in: failing).waitForNonExistence(timeout: 10))
        XCTAssertTrue(doseRow(in: failing).label.contains("Quibbanol"), doseRow(in: failing).label)
    }

    func testTheEntryDeleteAlertFromEditEntryAsksInTheEntryWords() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        let painRow = app.descendants(matching: .any)["entry-row-pain"]
        XCTAssertTrue(painRow.waitForExistence(timeout: 10))
        painRow.tap()
        let delete = app.buttons["delete-entry"]
        XCTAssertTrue(delete.waitForExistence(timeout: 10))
        delete.tap()

        let alert = app.alerts["Delete this entry? This can't be undone."].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertEqual(alert.buttons["confirm-delete"].firstMatch.label, "Delete entry")
        alert.buttons["keep-entry"].firstMatch.tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 10))
    }

    private func logZorblexDose(_ app: XCUIApplication) {
        addZorblex(app)
        app.buttons["save-dose"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
    }

    /// Makes Quibbanol, then a Zorblex with a 30 minute check-in, and saves a Zorblex dose an hour back that takes
    /// the 4 of 10 reading an hour back. The dose is then waiting for its check-in.
    private func logZorblexDoseCheckingInLater(_ app: XCUIApplication) throws {
        try skipUnlessAnHourBackStaysToday()
        saveEntryAnHourBack(.pain, in: app)
        tapLogMedication(in: app)
        addMedication("Quibbanol", in: app)
        app.buttons["log-dose-cancel"].tap()
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
    }

    private func checkInRow(in app: XCUIApplication) -> XCUIElement {
        identified("check-in-row", in: app)
    }

    /// The dose row keeps its label, so the time, medication and reading read the same as before.
    private func assertDoseUnchanged(_ label: String, in app: XCUIApplication) {
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
        XCTAssertEqual(doseRow(in: app).label, label)
        XCTAssertEqual(app.alerts.count, 0)
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
}
