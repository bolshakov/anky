// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class ScaleNoteTests: XCTestCase {
    func testHistoryNotesTheScaleOnceUnderTheLastDay() {
        continueAfterFailure = false
        let app = launchAnky()
        logEntry(4, in: app)
        logEntry(6, yesterday: true, in: app)
        showHistory(in: app)

        let note = app.staticTexts["Levels are 0 to 10."]
        XCTAssertTrue(note.waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", "Levels are 0 to 10.")).count, 1)

        XCTAssertEqual(dayHeaderLabels(in: app), ["Today", "Yesterday"])
        let yesterdayHeader = app.descendants(matching: .any).matching(identifier: "day-header").element(boundBy: 1)
        let lowestRow = entryRows(in: app).allElementsBoundByIndex.map(\.frame.maxY).max() ?? 0
        XCTAssertGreaterThanOrEqual(note.frame.minY, lowestRow)
        XCTAssertEqual(note.frame.minX, yesterdayHeader.frame.minX, accuracy: 1)
    }

    func testHistoryHasNoScaleNoteWithoutEntries() {
        continueAfterFailure = false
        let app = launchAnky()
        showHistory(in: app)

        XCTAssertTrue(app.staticTexts["No entries yet"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Levels are 0 to 10."].exists)
    }
}
