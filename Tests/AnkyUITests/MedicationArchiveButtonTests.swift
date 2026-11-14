// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// Archive and Restore are buttons in the top bar of Edit Medication, and neither asks for a confirmation.
@MainActor
final class MedicationArchiveButtonTests: XCTestCase {
    func testArchivingFromTheButtonDropsAnUnsavedEditAndAsksNothing() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        saveNewMedication(named: "Zorblex", app)
        openMedicationsFromLogDose(app)
        openMedicationFromList(app)

        let name = app.textFields["medication-name"]
        name.tap()
        name.typeText(" edited")
        choose("medication-archive", from: app)

        XCTAssertTrue(name.waitForNonExistence(timeout: 10))
        XCTAssertEqual(app.sheets.count, 0)
        XCTAssertTrue(app.buttons["archived-card"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "medication-row").count, 0)

        app.buttons["archived-card"].tap()
        let archived = app.buttons["archived-row"]
        XCTAssertTrue(archived.waitForExistence(timeout: 10))
        XCTAssertTrue(archived.label.hasPrefix("Zorblex"))
        XCTAssertFalse(archived.label.contains("edited"))
    }

    func testRestoringTheLastArchivedMedicationFromTheButtonClosesBothScreens() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        saveNewMedication(named: "Zorblex", app)
        openMedicationsFromLogDose(app)
        openMedicationFromList(app)
        choose("medication-archive", from: app)
        XCTAssertTrue(app.buttons["archived-card"].waitForExistence(timeout: 10))
        app.buttons["archived-card"].tap()
        app.buttons["archived-row"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))

        choose("medication-restore", from: app)

        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(app.sheets.count, 0)
        XCTAssertTrue(app.buttons["medication-row"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["archived-row"].exists)
        XCTAssertFalse(app.buttons["archived-card"].exists)
    }

    func testNewMedicationHasNoArchiveButton() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)

        XCTAssertFalse(app.buttons["medication-archive"].exists)
        XCTAssertFalse(app.buttons["medication-restore"].exists)
    }

    private func choose(_ item: String, from app: XCUIApplication) {
        let button = app.buttons[item]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "no button \(item)")
        button.tap()
    }
}
