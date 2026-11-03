// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class TodayListTests: XCTestCase {
    func testFirstEntrySavedFromEmptyTodayShowsTheSectionAtOnce() {
        continueAfterFailure = false
        let app = launchAnky()
        XCTAssertTrue(app.staticTexts["empty-today"].waitForExistence(timeout: 10))

        openNewEntry(app)
        saveEntry(app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["empty-today"].exists)
        XCTAssertTrue(app.staticTexts["Levels are 0 to 10. Stored on this iPhone only."].waitForExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 1)

        let chip = app.buttons["repeat-chip"]
        XCTAssertTrue(chip.waitForExistence(timeout: 10))
        XCTAssertLessThanOrEqual(chip.frame.maxY, row.frame.minY)
    }

    func testRepeatChipThenUndoKeepsTheListRight() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        saveEntry(app)

        let chip = app.buttons["repeat-chip"]
        XCTAssertTrue(chip.waitForExistence(timeout: 10))
        chip.tap()

        let undo = app.buttons["repeat-undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["repeat-chip"].exists)
        XCTAssertEqual(entryRows(in: app).count, 2)

        undo.tap()

        XCTAssertTrue(app.buttons["repeat-chip"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["repeat-undo"].exists)
        XCTAssertEqual(entryRows(in: app).count, 1)
    }

    func testTapOnLoggedTextDoesNotUndoButUndoStillDoes() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        saveEntry(app)

        let chip = app.buttons["repeat-chip"]
        XCTAssertTrue(chip.waitForExistence(timeout: 10))
        chip.tap()

        let logged = app.descendants(matching: .any)["repeat-logged"]
        XCTAssertTrue(logged.waitForExistence(timeout: 10))
        logged.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).tap()

        XCTAssertTrue(logged.exists)
        XCTAssertTrue(app.buttons["repeat-undo"].exists)
        XCTAssertEqual(entryRows(in: app).count, 2)

        app.buttons["repeat-undo"].tap()

        XCTAssertTrue(app.buttons["repeat-chip"].waitForExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 1)
    }

    /// The element tree lists the bottom inset's button before the list, so the order is checked by position on screen.
    func testTodayStopsRunTopToBottom() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        saveEntry(app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let footnote = app.staticTexts["Levels are 0 to 10. Stored on this iPhone only."]
        let stops = [app.staticTexts["today-date"], app.buttons["repeat-chip"], row, footnote, app.buttons["log-entry"]]
        for stop in stops {
            XCTAssertTrue(stop.exists)
        }
        let tops = stops.map(\.frame.minY)
        XCTAssertEqual(tops, tops.sorted())
        XCTAssertEqual(Set(tops).count, tops.count)
    }
}
