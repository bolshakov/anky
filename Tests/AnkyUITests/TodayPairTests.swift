// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class TodayPairTests: XCTestCase {
    func testPairSitsSideBySideAtDefaultSize() {
        continueAfterFailure = false
        let app = launchAnky()
        assertPairInOneRow(app)
    }

    func testPairSitsSideBySideAtLargestSize() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        assertPairInOneRow(app)
    }

    func testPairLabelsShareOneHeightInRussian() {
        continueAfterFailure = false
        let app = launchAnky(presentation: .region(language: "ru", region: "RU"))
        assertPairInOneRow(app)
    }

    func testLastRowClearsThePairAtDefaultSize() {
        continueAfterFailure = false
        let app = launchAnky()
        assertLastRowClearsPairAfterScrolling(app)
    }

    func testLastRowClearsThePairAtLargestSize() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        assertLastRowClearsPairAfterScrolling(app)
    }

    private func assertPairInOneRow(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let medication = app.buttons["log-medication"]
        let entry = app.buttons["log-entry"]
        XCTAssertTrue(medication.waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertTrue(entry.waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertEqual(medication.frame.minY, entry.frame.minY, accuracy: 1, file: file, line: line)
        XCTAssertEqual(medication.frame.height, entry.frame.height, accuracy: 1, file: file, line: line)
        XCTAssertEqual(medication.frame.width, entry.frame.width, accuracy: 1, file: file, line: line)
        XCTAssertLessThanOrEqual(medication.frame.maxX, entry.frame.minX, file: file, line: line)
    }

    private func assertLastRowClearsPairAfterScrolling(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        logEntries(8, in: app)
        let rows = entryRows(in: app)
        let pairTop = app.buttons["log-entry"].frame.minY
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertGreaterThan(lowestRowBottom(in: rows), pairTop, file: file, line: line)

        for _ in 0 ..< 5 where lowestRowBottom(in: rows) > pairTop {
            app.swipeUp()
        }
        XCTAssertLessThanOrEqual(lowestRowBottom(in: rows), pairTop, file: file, line: line)
    }

    private func logEntries(_ count: Int, in app: XCUIApplication) {
        for _ in 0 ..< count {
            openNewEntry(app)
            saveEntry(app)
            XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))
        }
    }

    private func lowestRowBottom(in rows: XCUIElementQuery) -> CGFloat {
        rows.allElementsBoundByIndex.map(\.frame.maxY).max() ?? 0
    }
}
