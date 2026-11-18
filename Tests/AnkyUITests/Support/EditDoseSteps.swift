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

/// Taps Add medication where Log Dose has it: on the form while the log has no medication, and on Select medication,
/// pushed from the Medication row, once it has one.
@MainActor
func tapAddMedication(in app: XCUIApplication) {
    let field = app.descendants(matching: .any)["dose-medication-field"]
    let none = app.descendants(matching: .any)["dose-no-medications"]
    let deadline = Date.now.addingTimeInterval(10)
    while !field.exists, !none.exists, Date.now < deadline {
        RunLoop.current.run(until: .now.addingTimeInterval(0.1))
    }
    if field.exists {
        field.tap()
    }
    app.buttons["dose-add-medication"].tap()
}

@MainActor
func chooseMedication(_ medication: String, in app: XCUIApplication) {
    let field = app.descendants(matching: .any)["dose-medication-field"]
    XCTAssertTrue(field.waitForExistence(timeout: 10))
    field.tap()
    let row = medicationRows(in: app).allElementsBoundByIndex.first { $0.label.contains(medication) }
    XCTAssertNotNil(row, "no medication row for \(medication)")
    row?.tap()
}

@MainActor
func medicationRows(in app: XCUIApplication) -> XCUIElementQuery {
    app.descendants(matching: .any).matching(identifier: "dose-medication-row")
}

/// The name the Medication row of the form shows.
@MainActor
func selectedMedication(in app: XCUIApplication) -> String? {
    let field = app.descendants(matching: .any)["dose-medication-field"]
    XCTAssertTrue(field.waitForExistence(timeout: 10))
    return ["Zorblex", "Quibbanol"].first { field.label.contains($0) }
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
