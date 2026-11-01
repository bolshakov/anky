// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class MedicationRowHeightTests: XCTestCase {
    func testMedicationAndArchivedRowsAreSixtyPointsTall() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(in: app)
        app.buttons["log-dose-manage"].tap()

        let row = app.buttons["medication-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        assertSixtyPoints(row)

        archiveByPartialSwipe(row, in: app)
        app.buttons["archived-card"].tap()

        let archived = app.buttons["archived-row"]
        XCTAssertTrue(archived.waitForExistence(timeout: 10))
        assertSixtyPoints(archived)
    }

    func testMedicationRowGrowsWithLargestText() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        addZorblex(in: app)
        app.buttons["log-dose-manage"].tap()

        let row = app.buttons["medication-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(row.frame.height, 60)
    }

    private func addZorblex(in app: XCUIApplication) {
        app.buttons["log-medication"].tap()
        app.buttons["dose-add-medication"].tap()

        let name = app.textFields["medication-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Zorblex")
        app.buttons["medication-save"].tap()

        XCTAssertTrue(app.buttons["dose-add-medication"].waitForExistence(timeout: 10))
    }

    /// Drags about 40 % of the row's width. That reveals Archive, and a full swipe would archive at once.
    private func archiveByPartialSwipe(_ row: XCUIElement, in app: XCUIApplication) {
        let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let end = row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)

        let archive = app.buttons["Archive"]
        XCTAssertTrue(archive.waitForExistence(timeout: 10))
        archive.tap()
    }

    private func assertSixtyPoints(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertGreaterThanOrEqual(element.frame.height, 60, file: file, line: line)
        XCTAssertLessThan(element.frame.height, 61, file: file, line: line)
    }
}
