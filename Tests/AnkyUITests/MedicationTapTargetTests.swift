// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class MedicationTapTargetTests: XCTestCase {
    func testLogDoseCancelIsAtLeast44Square() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()

        assertAtLeast44Square(app.buttons["log-dose-cancel"])
    }

    func testMedicationFormCancelAndFieldsAreAtLeast44() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)

        assertAtLeast44Square(app.buttons["medication-cancel"])
        XCTAssertGreaterThanOrEqual(app.textFields["medication-name"].frame.height, 44)
        XCTAssertGreaterThanOrEqual(app.textFields["medication-strength"].frame.height, 44)
    }

    func testNameAndStrengthFocusFromTheirTopAndBottomEdges() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        let name = app.textFields["medication-name"]
        let strength = app.textFields["medication-strength"]

        tapEdgeAndType(app, name, edge: 0.1, typed: "Zorblex")
        tapEdgeAndType(app, strength, edge: 0.1, typed: "Quibbanol")
        tapEdgeAndType(app, name, edge: 0.9, typed: "Vexlorp")
        tapEdgeAndType(app, strength, edge: 0.9, typed: "Hambrel")
    }

    private func tapEdgeAndType(_ app: XCUIApplication, _ field: XCUIElement, edge: CGFloat, typed: String) {
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: edge)).tap()
        app.typeText(typed)

        XCTAssertTrue((field.value as? String ?? "").contains(typed))
    }

    private func openNewMedication(_ app: XCUIApplication) {
        app.buttons["log-medication"].tap()
        app.buttons["dose-add-medication"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))
    }

    private func assertAtLeast44Square(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertGreaterThanOrEqual(element.frame.width, 44, file: file, line: line)
        XCTAssertGreaterThanOrEqual(element.frame.height, 44, file: file, line: line)
    }
}
