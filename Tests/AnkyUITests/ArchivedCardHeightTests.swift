// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class ArchivedCardHeightTests: XCTestCase {
    func testArchivedCardIsAtLeast60PointsTall() {
        continueAfterFailure = false
        let app = launchAnky()
        addMedication(app, name: "Zorblex")

        app.buttons["log-dose-manage"].tap()
        archiveFirstMedication(app)

        let card = app.buttons["archived-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(card.frame.height, 60)
        XCTAssertLessThan(card.frame.height, 61)
    }

    private func addMedication(_ app: XCUIApplication, name: String) {
        app.buttons["log-medication"].tap()
        app.buttons["dose-add-medication"].tap()

        let field = app.textFields["medication-name"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(name)
        app.buttons["medication-save"].tap()

        XCTAssertTrue(app.buttons["dose-add-medication"].waitForExistence(timeout: 10))
    }

    private func archiveFirstMedication(_ app: XCUIApplication) {
        let row = app.buttons["medication-row"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let end = row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)

        let archive = app.buttons["Archive"]
        XCTAssertTrue(archive.waitForExistence(timeout: 10))
        archive.tap()
    }
}
