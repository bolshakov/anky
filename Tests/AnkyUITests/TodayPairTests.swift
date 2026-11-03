// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class TodayPairTests: XCTestCase {
    func testPairSitsSideBySideAtDefaultSize() {
        continueAfterFailure = false
        let app = launchAnky()
        assertPairInOneRow(app)
    }

    func testPairStacksAtLargestSize() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        assertPairStacked(app)
    }

    func testPairStacksAtLargestSizeInRussian() {
        continueAfterFailure = false
        let app = launchAnky(
            presentation: .region(language: "ru", region: "RU"),
            arguments: largestTextArguments
        )
        assertPairStacked(app)
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

    private func assertPairStacked(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let medication = app.buttons["log-medication"]
        let entry = app.buttons["log-entry"]
        XCTAssertTrue(medication.waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertTrue(entry.waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertEqual(medication.frame.minX, entry.frame.minX, accuracy: 1, file: file, line: line)
        XCTAssertEqual(medication.frame.width, entry.frame.width, accuracy: 1, file: file, line: line)
        XCTAssertLessThanOrEqual(medication.frame.maxY, entry.frame.minY, file: file, line: line)
    }

    private func assertLastRowClearsPairAfterScrolling(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        logEntries(8, in: app)
        let rows = entryRows(in: app)
        let pairTop = app.buttons["log-medication"].frame.minY
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertGreaterThan(lowestRowBottom(in: rows), pairTop, file: file, line: line)

        scrollRowsToRest(in: app, rows: rows)
        XCTAssertGreaterThan(rows.count, 0, file: file, line: line)
        XCTAssertLessThanOrEqual(lowestRowBottom(in: rows), pairTop, file: file, line: line)
    }

    /// At the largest size a swipe from the screen centre leaves the list where it was, so the drag starts above the
    /// pair and repeats until the rows stop moving at the end of the list.
    private func scrollRowsToRest(in app: XCUIApplication, rows: XCUIElementQuery) {
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05))
        var previous = rowTops(in: rows)
        for _ in 0 ..< 12 {
            from.press(forDuration: 0.05, thenDragTo: to)
            let current = rowTops(in: rows)
            if current == previous {
                return
            }
            previous = current
        }
        XCTFail("the list did not come to rest after scrolling")
    }

    private func logEntries(_ count: Int, in app: XCUIApplication) {
        for _ in 0 ..< count {
            openNewEntry(app)
            saveEntry(app)
            XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))
        }
    }

    private func rowTops(in rows: XCUIElementQuery) -> [CGFloat] {
        rows.allElementsBoundByIndex.map(\.frame.minY)
    }

    private func lowestRowBottom(in rows: XCUIElementQuery) -> CGFloat {
        rows.allElementsBoundByIndex.map(\.frame.maxY).max() ?? 0
    }
}
