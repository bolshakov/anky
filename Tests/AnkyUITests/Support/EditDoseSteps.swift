// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// Leaves Log Dose open with its medication chosen.
@MainActor
func addZorblex(_ app: XCUIApplication) {
    tapLogMedication(in: app)
    addMedication("Zorblex", in: app)
    XCTAssertTrue(app.buttons["log-how-you-feel-row"].waitForExistence(timeout: 10))
}

/// Adds a medication from Log Dose, which is left open with it chosen.
@MainActor
func addMedication(_ medication: String, in app: XCUIApplication) {
    tapAddMedication(in: app)
    let name = app.textFields["medication-name"]
    XCTAssertTrue(name.waitForExistence(timeout: 10))
    name.tap()
    name.typeText(medication)
    let save = app.buttons["medication-save"]
    save.tap()
    XCTAssertTrue(save.waitForNonExistence(timeout: 10))
}

/// Taps Add medication, the last row of the Medication card.
@MainActor
func tapAddMedication(in app: XCUIApplication) {
    let add = app.buttons["dose-add-medication"]
    XCTAssertTrue(add.waitForExistence(timeout: 10))
    add.tap()
}

@MainActor
func chooseMedication(_ medication: String, in app: XCUIApplication) {
    XCTAssertTrue(medicationRows(in: app).firstMatch.waitForExistence(timeout: 10))
    let row = medicationRows(in: app).allElementsBoundByIndex.first { $0.label.contains(medication) }
    XCTAssertNotNil(row, "no medication row for \(medication)")
    row?.tap()
}

@MainActor
func medicationRows(in app: XCUIApplication) -> XCUIElementQuery {
    app.descendants(matching: .any).matching(identifier: "dose-medication-row")
}

/// The name on the selected row of the Medication card.
@MainActor
func selectedMedication(in app: XCUIApplication) -> String? {
    XCTAssertTrue(medicationRows(in: app).firstMatch.waitForExistence(timeout: 10))
    let selected = medicationRows(in: app).allElementsBoundByIndex.first(where: \.isSelected)
    return ["Zorblex", "Quibbanol"].first { selected?.label.contains($0) == true }
}

@MainActor
func swipeSheetDown(_ app: XCUIApplication) {
    let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
    let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
    start.press(forDuration: 0.1, thenDragTo: end)
}

@MainActor
func doseRow(in app: XCUIApplication) -> XCUIElement {
    app.descendants(matching: .any)["dose-row"]
}

@MainActor
func editDoseScreen(in app: XCUIApplication) -> XCUIElement {
    app.descendants(matching: .any)["edit-dose-screen"]
}
