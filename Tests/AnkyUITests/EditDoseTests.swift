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
        let rowTime = doseRowTime(of: rowLabel)
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
        try logZorblexDoseAnHourBack(app)

        let rowLabel = doseRow(in: app).label
        doseRow(in: app).tap()

        XCTAssertTrue(editDoseScreen(in: app).waitForExistence(timeout: 10))
        XCTAssertEqual(medicationRows(in: app).count, 2)
        XCTAssertEqual(selectedMedication(in: app), "Zorblex")
        let day = dateRowDay(in: app) ?? ""
        XCTAssertTrue(day.hasPrefix("Today"), "date row day is \(day)")
        let rowTime = doseRowTime(of: rowLabel)
        XCTAssertEqual(dateRowTime(in: app), rowTime, rowLabel)
        let before = app.buttons["before-reading-row"]
        XCTAssertTrue(before.waitForExistence(timeout: 10))
        XCTAssertTrue(before.label.contains("4 of 10"), before.label)
        XCTAssertTrue(app.buttons["save-dose-changes"].exists)
        XCTAssertTrue(app.buttons["edit-dose-cancel"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["log-dose-manage"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["dose-add-medication"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["check-in-later"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["dose-check-in-after"].exists)
        attachScreenshot(named: "edit-dose")
    }

    func testACancelledChangeAsksAndASwipeCannotCloseIt() throws {
        continueAfterFailure = false
        let app = launchAnky()
        try logZorblexDoseAnHourBack(app)
        let label = doseRow(in: app).label

        doseRow(in: app).tap()
        chooseMedication("Quibbanol", in: app)
        setDateToYesterday(in: app)
        app.buttons["edit-dose-cancel"].tap()
        discardChanges(in: app)

        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))
        assertDoseUnchanged(label, in: app)

        doseRow(in: app).tap()
        chooseMedication("Quibbanol", in: app)
        setDateToYesterday(in: app)
        swipeSheetDown(app)

        XCTAssertTrue(editDoseScreen(in: app).exists)
        app.buttons["edit-dose-cancel"].tap()
        discardChanges(in: app)

        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))
        assertDoseUnchanged(label, in: app)
    }

    func testSaveChangesWithAnotherMedicationKeepsTheReading() throws {
        continueAfterFailure = false
        let app = launchAnky()
        try logZorblexDoseAnHourBack(app)

        doseRow(in: app).tap()
        chooseMedication("Quibbanol", in: app)
        app.buttons["save-dose-changes"].tap()

        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(doseRow(in: app).label.contains("Quibbanol"), doseRow(in: app).label)
        XCTAssertTrue(doseRow(in: app).label.contains("4 of 10"), doseRow(in: app).label)
    }

    func testAMovedDoseShowsUnderYesterdayInHistory() throws {
        continueAfterFailure = false
        let app = launchAnky()
        try logZorblexDoseAnHourBack(app)
        let timeBeforeMove = doseRowTime(of: doseRow(in: app).label)

        doseRow(in: app).tap()
        setDateToYesterday(in: app)
        app.buttons["save-dose-changes"].tap()

        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))
        XCTAssertTrue(doseRow(in: app).waitForNonExistence(timeout: 10))
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
        let yesterday = try XCTUnwrap(
            app.descendants(matching: .any).matching(identifier: "day-label")
                .allElementsBoundByIndex.first { $0.label == "Yesterday" },
            "headers are \(dayHeaderLabels(in: app))"
        )
        XCTAssertGreaterThan(doseRow(in: app).frame.minY, yesterday.frame.minY)
        let movedLabel = doseRow(in: app).label
        XCTAssertEqual(doseRowTime(of: movedLabel), timeBeforeMove, movedLabel)
        XCTAssertTrue(movedLabel.contains("Zorblex"), movedLabel)
        XCTAssertTrue(movedLabel.contains("4 of 10"), movedLabel)
        app.tabBars.buttons["Today"].tap()
    }

    func testAFailedSaveKeepsEditDoseOpenOnTheChosenMedication() throws {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        try logZorblexDoseAnHourBack(app)
        app.terminate()

        let failing = launchAnky(folder: folder, arguments: ["-ANKY_FAIL_MEDICATION_WRITES", "1"])
        XCTAssertTrue(doseRow(in: failing).waitForExistence(timeout: 10))
        let original = doseRow(in: failing).label
        doseRow(in: failing).tap()
        chooseMedication("Quibbanol", in: failing)
        failing.buttons["save-dose-changes"].tap()

        let alert = failing.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertEqual(alert.label, "Couldn't save this dose. Try again.")
        XCTAssertEqual(alert.buttons.count, 1)
        alert.buttons["OK"].tap()
        XCTAssertTrue(editDoseScreen(in: failing).waitForExistence(timeout: 10))
        XCTAssertEqual(selectedMedication(in: failing), "Quibbanol")
        XCTAssertTrue(failing.buttons["save-dose-changes"].isEnabled)

        failing.buttons["edit-dose-cancel"].tap()
        discardChanges(in: failing)
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
        chooseDeleteEntry(in: app)

        let alert = app.alerts["Delete this entry? This can't be undone."].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertEqual(alert.buttons["confirm-delete"].firstMatch.label, "Delete entry")
        alert.buttons["keep-entry"].firstMatch.tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 10))
    }

    func testCancellingTheDoseDeleteAlertKeepsTheDose() {
        continueAfterFailure = false
        let app = launchAnky()
        logZorblexDose(app)
        doseRow(in: app).tap()
        XCTAssertTrue(editDoseScreen(in: app).waitForExistence(timeout: 10))
        chooseDeleteDose(in: app)

        let alert = app.alerts["Delete this dose? This can't be undone."].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertEqual(alert.buttons["confirm-delete"].firstMatch.label, "Delete dose")
        alert.buttons["keep-entry"].firstMatch.tap()

        XCTAssertTrue(alert.waitForNonExistence(timeout: 10))
        XCTAssertTrue(editDoseScreen(in: app).exists)
        app.buttons["edit-dose-cancel"].tap()
        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))
        XCTAssertTrue(doseRow(in: app).exists)
    }

    func testConfirmingTheDoseDeleteAlertRemovesTheDoseAndClosesTheScreen() {
        continueAfterFailure = false
        let app = launchAnky()
        logZorblexDose(app)
        doseRow(in: app).tap()
        XCTAssertTrue(editDoseScreen(in: app).waitForExistence(timeout: 10))
        chooseDeleteDose(in: app)

        let alert = app.alerts["Delete this dose? This can't be undone."].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        alert.buttons["confirm-delete"].firstMatch.tap()

        XCTAssertTrue(editDoseScreen(in: app).waitForNonExistence(timeout: 10))
        XCTAssertTrue(doseRow(in: app).waitForNonExistence(timeout: 10))
    }

    private func chooseDeleteDose(in app: XCUIApplication) {
        let more = app.buttons["dose-more"]
        XCTAssertTrue(more.waitForExistence(timeout: 10))
        more.tap()
        let delete = app.buttons["Delete dose"]
        XCTAssertTrue(delete.waitForExistence(timeout: 10))
        delete.tap()
    }

    private func logZorblexDose(_ app: XCUIApplication) {
        addZorblex(app)
        app.buttons["save-dose"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
    }

    /// Makes Quibbanol, then a Zorblex with no check-in delay, and saves a Zorblex dose an hour back that takes the
    /// 4 of 10 reading an hour back. The dose is not waiting, so its row opens Edit Dose.
    private func logZorblexDoseAnHourBack(_ app: XCUIApplication) throws {
        try skipUnlessAnHourBackStaysToday()
        saveEntryAnHourBack(.pain, in: app)
        tapLogMedication(in: app)
        addMedication("Quibbanol", in: app)
        app.buttons["log-dose-cancel"].tap()
        tapLogMedication(in: app)
        addMedication("Zorblex", in: app)
        saveDoseAnHourBack(in: app)
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
    }

    /// The dose row keeps its label, so the time, medication and reading read the same as before.
    private func assertDoseUnchanged(_ label: String, in app: XCUIApplication) {
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
        XCTAssertEqual(doseRow(in: app).label, label)
        XCTAssertEqual(app.alerts.count, 0)
    }

    private func logFourOfTenBeforeTheDose(_ app: XCUIApplication) {
        app.buttons["log-how-you-feel-row"].tap()
        XCTAssertTrue(entryScreen(app).waitForExistence(timeout: 10))
        setSeverity(4, in: app)
        saveEntry(app)
        XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))
    }

    private func deleteTodaysPainEntry(in app: XCUIApplication) {
        let painRow = app.descendants(matching: .any)["entry-row-pain"]
        XCTAssertTrue(painRow.waitForExistence(timeout: 10))
        painRow.tap()
        chooseDeleteEntry(in: app)
        app.buttons["confirm-delete"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["edit-entry-screen"].waitForNonExistence(timeout: 10))
    }
}
