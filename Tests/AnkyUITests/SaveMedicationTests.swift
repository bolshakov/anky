// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class SaveMedicationTests: XCTestCase {
    func testTwoQuickTapsOnSaveMakeOneMedication() {
        continueAfterFailure = false
        let app = launchAnky()
        tapLogMedication(in: app)
        app.buttons["dose-add-medication"].tap()

        let name = app.textFields["medication-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Zorblex")

        let save = app.buttons["medication-save"]
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        XCTAssertLessThanOrEqual(save.frame.maxY, app.keyboards.firstMatch.frame.minY)
        save.doubleTap()

        XCTAssertTrue(save.waitForNonExistence(timeout: 10))
        let field = app.descendants(matching: .any)["dose-medication-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        let saved = field.label
        XCTAssertTrue(saved.contains("Zorblex"), "the typed name was not saved: \(saved)")
        field.tap()
        XCTAssertEqual(medicationRows(in: app).count, 1)
    }

    func testNewStrengthIsSavedAsTyped() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        typeInto(app.textFields["medication-name"], "Zorblex")
        typeInto(app.textFields["medication-strength"], "500 mcg")
        saveMedication(app)

        openManage(app)
        openFirstMedication(app)
        XCTAssertEqual(app.textFields["medication-strength"].value as? String, "500 mcg")
    }

    func testEditedStrengthIsSavedAsTyped() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        typeInto(app.textFields["medication-name"], "Zorblex")
        typeInto(app.textFields["medication-strength"], "500 mcg")
        saveMedication(app)

        openManage(app)
        openFirstMedication(app)
        let strength = app.textFields["medication-strength"]
        clear(strength)
        typeInto(strength, "5 mg/ml")
        saveMedication(app)

        openFirstMedication(app)
        XCTAssertEqual(app.textFields["medication-strength"].value as? String, "5 mg/ml")
    }

    func testReturnMovesToStrengthAndKeepsTheName() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        typeInto(app.textFields["medication-name"], "Zorblex")
        app.typeText("\n")
        app.typeText("500 mcg")

        XCTAssertEqual(app.textFields["medication-name"].value as? String, "Zorblex")
        XCTAssertEqual(app.textFields["medication-strength"].value as? String, "500 mcg")
        saveMedication(app)

        openManage(app)
        openFirstMedication(app)
        XCTAssertEqual(app.textFields["medication-name"].value as? String, "Zorblex")
        XCTAssertEqual(app.textFields["medication-strength"].value as? String, "500 mcg")
    }

    private func openNewMedication(_ app: XCUIApplication) {
        tapLogMedication(in: app)
        app.buttons["dose-add-medication"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))
    }

    private func openManage(_ app: XCUIApplication) {
        app.buttons["log-dose-manage"].tap()
        XCTAssertTrue(app.buttons["medication-row"].firstMatch.waitForExistence(timeout: 10))
    }

    private func openFirstMedication(_ app: XCUIApplication) {
        app.buttons["medication-row"].firstMatch.tap()
        XCTAssertTrue(app.textFields["medication-strength"].waitForExistence(timeout: 10))
    }

    private func typeInto(_ field: XCUIElement, _ text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(text)
    }

    /// Tapping the field's centre puts the cursor after the text, so deleting from there clears it.
    private func clear(_ field: XCUIElement) {
        let length = (field.value as? String ?? "").count
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: length + 5))
    }

    private func saveMedication(_ app: XCUIApplication) {
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))
    }
}
