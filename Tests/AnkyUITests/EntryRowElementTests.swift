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
        assertOneButtonRow(row)

        row.tap()
        XCTAssertTrue(app.buttons["save-entry"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["save-entry"].label, "Save changes")
    }

    func testHistoryRowIsOneButtonAndOpensEditEntry() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        showHistory(in: app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        assertOneButtonRow(row)

        row.tap()
        XCTAssertTrue(app.buttons["save-entry"].waitForExistence(timeout: 10))
    }

    private func assertOneButtonRow(_ row: XCUIElement) {
        XCTAssertEqual(row.elementType, .button)
        XCTAssertEqual(row.identifier, "entry-row-pain")
        XCTAssertTrue(row.label.hasSuffix(", Pain, 4 of 10"), "row label is \(row.label)")
    }
}
