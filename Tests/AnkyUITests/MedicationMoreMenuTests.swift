// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// Archive and Restore live in the ••• menu of Edit Medication, and neither asks for a confirmation.
@MainActor
final class MedicationMoreMenuTests: XCTestCase {
    func testArchivingFromTheMenuDropsAnUnsavedEditAndAsksNothing() {
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

    func testRestoringTheLastArchivedMedicationFromTheMenuClosesBothScreens() {
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

    func testNewMedicationHasNoMenu() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)

        XCTAssertFalse(app.buttons["medication-more"].exists)
    }

    private func choose(_ item: String, from app: XCUIApplication) {
        let more = app.buttons["medication-more"]
        XCTAssertTrue(more.waitForExistence(timeout: 10))
        more.tap()
        let entry = app.buttons[item]
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "no menu item \(item)")
        entry.tap()
    }
}
