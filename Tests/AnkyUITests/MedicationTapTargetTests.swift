// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class MedicationTapTargetTests: XCTestCase {
    func testLogDoseCancelIsTheSystemSize() {
        continueAfterFailure = false
        let app = launchAnky()
        tapLogMedication(in: app)

        assertSystemCancelSize(app.buttons["log-dose-cancel"])
    }

    func testNewEntryCancelIsTheSystemSize() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        assertSystemCancelSize(app.buttons["cancel-entry"])
    }

    func testMedicationFormCancelIsTheSystemSizeAndFieldsAreAtLeast44() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)

        assertSystemCancelSize(app.buttons["medication-cancel"])
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
        tapLogMedication(in: app)
        app.buttons["dose-add-medication"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))
    }

    /// The close button is the system's, which the app cannot enlarge, so it is held to the size the system draws.
    private func assertSystemCancelSize(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertGreaterThanOrEqual(element.frame.width, 36, file: file, line: line)
        XCTAssertGreaterThanOrEqual(element.frame.height, 36, file: file, line: line)
    }
}
