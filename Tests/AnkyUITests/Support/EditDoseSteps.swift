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
    app.buttons["dose-add-medication"].tap()
    let name = app.textFields["medication-name"]
    XCTAssertTrue(name.waitForExistence(timeout: 10))
    name.tap()
    name.typeText(medication)
    let save = app.buttons["medication-save"]
    save.tap()
    XCTAssertTrue(save.waitForNonExistence(timeout: 10))
}

@MainActor
func chooseMedication(_ medication: String, in app: XCUIApplication) {
    let row = medicationRows(in: app).allElementsBoundByIndex.first { $0.label.contains(medication) }
    XCTAssertNotNil(row, "no medication row for \(medication)")
    row?.tap()
}

@MainActor
func medicationRows(in app: XCUIApplication) -> XCUIElementQuery {
    app.descendants(matching: .any).matching(identifier: "dose-medication-row")
}

/// The name in the one medication row that is checked, read from the row's selected state.
@MainActor
func selectedMedication(in app: XCUIApplication) -> String? {
    let checked = medicationRows(in: app).allElementsBoundByIndex.filter(\.isSelected)
    XCTAssertEqual(checked.count, 1)
    return checked.first.flatMap { row in ["Zorblex", "Quibbanol"].first { row.label.contains($0) } }
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
