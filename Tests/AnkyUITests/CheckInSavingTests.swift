// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// Each test saves the check-in through one way into the medication form, relaunches on the same folder so the
/// medication is read back from the store, and opens it again to see what was saved.
@MainActor
final class CheckInSavingTests: XCTestCase {
    func testNewMedicationFromLogDoseSavesThreeHoursAndReopensOnIt() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        openNewMedication(app)
        nameNewMedication("Zorblex", in: app)
        choose("3 hours", in: app)
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))

        assertCheckInOn("3 hours", in: relaunchAndOpenMedication(named: "Zorblex", app, folder: folder))
    }

    /// Manage shows only once a medication exists, so a placeholder is saved first.
    func testNewMedicationFromMedicationsListSavesThreeHoursAndReopensOnIt() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        openNewMedication(app)
        saveNewMedication(named: "Quorbex", app)
        openMedicationsFromLogDose(app)
        openNewMedicationFromList(app)
        nameNewMedication("Zorblex", in: app)
        choose("3 hours", in: app)
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))

        assertCheckInOn("3 hours", in: relaunchAndOpenMedication(named: "Zorblex", app, folder: folder))
    }

    func testNewMedicationWithTheSwitchOffSavesNoCheckIn() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        openNewMedication(app)
        saveNewMedication(named: "Zorblex", app)

        let relaunched = relaunchAndOpenMedication(named: "Zorblex", app, folder: folder)
        XCTAssertEqual(checkInSwitch(in: relaunched).value as? String, "0")
        XCTAssertFalse(checkInMenu(in: relaunched).exists)
    }

    func testEditingAMedicationWithNoCheckInTurnsItOnAtFourHours() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        openNewMedication(app)
        saveNewMedication(named: "Zorblex", app)
        openMedicationsFromLogDose(app)
        openMedication(named: "Zorblex", in: app)
        scrollToCheckIn(in: app)
        XCTAssertEqual(checkInSwitch(in: app).value as? String, "0")

        choose("4 hours", in: app)
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))

        assertCheckInOn("4 hours", in: relaunchAndOpenMedication(named: "Zorblex", app, folder: folder))
    }

    func testEditingAMedicationThatStoresTwoHoursTurnsItOff() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        openNewMedication(app)
        nameNewMedication("Zorblex", in: app)
        choose("2 hours", in: app)
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))
        openMedicationsFromLogDose(app)
        openMedication(named: "Zorblex", in: app)
        scrollToCheckIn(in: app)
        assertCheckInOn("2 hours", in: app)

        turnOffCheckIn(in: app)
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))

        let relaunched = relaunchAndOpenMedication(named: "Zorblex", app, folder: folder)
        XCTAssertEqual(checkInSwitch(in: relaunched).value as? String, "0")
        XCTAssertFalse(checkInMenu(in: relaunched).exists)
    }

    func testEditingAnArchivedMedicationSavesItsCheckInChange() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        openNewMedication(app)
        nameNewMedication("Zorblex", in: app)
        choose("2 hours", in: app)
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))
        openMedicationsFromLogDose(app)
        archiveFirstMedication(app)
        openArchivedMedication(app)
        scrollToCheckIn(in: app)
        assertCheckInOn("2 hours", in: app)

        turnOffCheckIn(in: app)
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))

        app.terminate()
        let relaunched = launchAnky(folder: folder)
        openLogDose(relaunched)
        openMedicationsFromLogDose(relaunched)
        openArchivedMedication(relaunched)
        scrollToCheckIn(in: relaunched)
        XCTAssertEqual(checkInSwitch(in: relaunched).value as? String, "0")
        XCTAssertFalse(checkInMenu(in: relaunched).exists)
    }

    func testCancelingNewMedicationAfterTurningTheSwitchOnSavesNothing() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        openNewMedication(app)
        nameNewMedication("Zorblex", in: app)
        turnOn(in: app)
        app.buttons["medication-cancel"].tap()
        discardChanges(in: app)
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))

        app.terminate()
        let relaunched = launchAnky(folder: folder)
        openLogDose(relaunched)
        XCTAssertTrue(identified("dose-no-medications", in: relaunched).waitForExistence(timeout: 10))
        XCTAssertFalse(relaunched.buttons["log-dose-manage"].exists)
    }

    private func assertCheckInOn(_ delay: String, in app: XCUIApplication) {
        XCTAssertEqual(checkInSwitch(in: app).value as? String, "1")
        XCTAssertEqual(checkInMenu(in: app).value as? String, delay)
    }

    private func turnOffCheckIn(in app: XCUIApplication) {
        checkInSwitch(in: app).coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        XCTAssertTrue(checkInMenu(in: app).waitForNonExistence(timeout: 10))
    }

    private func relaunchAndOpenMedication(
        named name: String,
        _ app: XCUIApplication,
        folder: String
    ) -> XCUIApplication {
        app.terminate()
        let relaunched = launchAnky(folder: folder)
        openLogDose(relaunched)
        openMedicationsFromLogDose(relaunched)
        openMedication(named: name, in: relaunched)
        scrollToCheckIn(in: relaunched)
        return relaunched
    }

    private func openMedication(named name: String, in app: XCUIApplication) {
        let row = app.buttons
            .matching(NSPredicate(format: "identifier == 'medication-row' AND label BEGINSWITH %@", name))
            .firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "no medication row for \(name)")
        row.tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))
    }

    private func openArchivedMedication(_ app: XCUIApplication) {
        app.buttons["archived-card"].tap()
        app.buttons["archived-row"].firstMatch.tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))
    }

    private func archiveFirstMedication(_ app: XCUIApplication) {
        let row = app.buttons["medication-row"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let end = row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)

        let archive = app.buttons["Archive"]
        XCTAssertTrue(archive.waitForExistence(timeout: 10))
        archive.tap()
        XCTAssertTrue(app.buttons["archived-card"].waitForExistence(timeout: 10))
    }
}
