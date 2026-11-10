// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class EntryRowElementTests: XCTestCase {
    func testTodayRowIsOneButtonAndOpensEditEntry() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        assertOneButtonRow(row, in: app)

        row.tap()
        XCTAssertTrue(app.buttons["save-entry"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["save-entry"].label, "Save")
    }

    func testHistoryRowIsOneButtonAndOpensEditEntry() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        showHistory(in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        assertOneButtonRow(row, in: app)

        row.tap()
        XCTAssertTrue(app.buttons["save-entry"].waitForExistence(timeout: 10))
    }

    func testLoggedCardIsReadAsOneTextApartFromUndoAndReturnsAfterUndo() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)

        app.buttons["repeat-chip"].tap()
        assertLoggedCardReadsAloud(in: app)

        app.buttons["repeat-undo"].tap()
        XCTAssertTrue(app.buttons["repeat-chip"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["repeat-logged"].exists)

        app.buttons["repeat-chip"].tap()
        assertLoggedCardReadsAloud(in: app)
    }

    private func assertLoggedCardReadsAloud(in app: XCUIApplication) {
        let logged = app.staticTexts["repeat-logged"]
        XCTAssertTrue(logged.waitForExistence(timeout: 10))
        XCTAssertTrue(logged.label.hasPrefix("Logged, Pain, "), "logged label is \(logged.label)")
        XCTAssertTrue(logged.label.hasSuffix(", 4 of 10"), "logged label is \(logged.label)")
        XCTAssertEqual(app.buttons["repeat-undo"].label, "Undo")
    }

    private func assertOneButtonRow(_ row: XCUIElement, in app: XCUIApplication) {
        XCTAssertEqual(row.elementType, .button)
        XCTAssertEqual(row.identifier, "entry-row-pain")
        XCTAssertTrue(row.label.hasPrefix("Pain, 4 of 10, "), "row label is \(row.label)")
        XCTAssertTrue(row.label.hasSuffix(", No place"), "row label is \(row.label)")
        let texts = app.staticTexts.allElementsBoundByIndex.filter { row.frame.contains($0.frame) }
        XCTAssertTrue(texts.isEmpty, "row texts are separate stops: \(texts.map(\.label))")
    }
}
