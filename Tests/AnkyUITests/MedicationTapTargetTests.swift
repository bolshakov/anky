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

        let taps = [
            EdgeTap(field: name, other: strength, edge: 0.1, typed: "Zorblex"),
            EdgeTap(field: strength, other: name, edge: 0.1, typed: "Quibbanol"),
            EdgeTap(field: name, other: strength, edge: 0.9, typed: "Vexlorp"),
            EdgeTap(field: strength, other: name, edge: 0.9, typed: "Hambrel"),
        ]
        for tap in taps {
            tap.field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: tap.edge)).tap()
            app.typeText(tap.typed)

            XCTAssertTrue((tap.field.value as? String ?? "").contains(tap.typed))
            XCTAssertFalse((tap.other.value as? String ?? "").contains(tap.typed))
        }
    }

    /// A tap at a fraction of the field's height, then the text typed into whichever field took focus.
    private struct EdgeTap {
        let field: XCUIElement
        let other: XCUIElement
        let edge: CGFloat
        let typed: String
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
