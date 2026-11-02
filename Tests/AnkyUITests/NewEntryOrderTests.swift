// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import XCTest

@MainActor
final class NewEntryOrderTests: XCTestCase {
    func testNewEntryWithRecentStartsWithChipsThenKind() {
        continueAfterFailure = false
        let app = launchAnky()
        saveFatigueEntry(in: app)

        openNewEntry(app)
        assertInOrder(["recent-chips", "kind-picker", "date-row", "severity-caption", "note-field"], in: app)
    }

    func testNewEntryWithoutRecentStartsWithKind() {
        continueAfterFailure = false
        let app = launchAnky()

        openNewEntry(app)
        XCTAssertFalse(element("recent-chips", in: app).exists)
        assertInOrder(["kind-picker", "date-row", "severity-caption", "note-field"], in: app)
    }

    func testRecentChipFillsKindAndSeverity() {
        continueAfterFailure = false
        let app = launchAnky()
        saveFatigueEntry(in: app)

        openNewEntry(app)
        let chip = app.buttons["recent-chip-0"]
        XCTAssertTrue(chip.waitForExistence(timeout: 10))
        chip.tap()
        XCTAssertTrue(kindSegment(.fatigue, in: app).isSelected)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 4)
    }

    func testEditFatigueHasNoWhereAndDeleteLast() {
        continueAfterFailure = false
        let app = launchAnky()
        saveFatigueEntry(in: app)

        let row = app.buttons["entry-row-fatigue"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        let screen = entryScreen(app, id: "edit-entry-screen")
        XCTAssertTrue(screen.waitForExistence(timeout: 10))
        XCTAssertFalse(element("where-section", in: app).exists)

        let delete = element("delete-entry", in: app)
        for _ in 0 ..< 3 where !delete.exists {
            screen.swipeUp()
        }
        assertInOrder(["kind-picker", "date-row", "severity-caption", "delete-entry"], in: app)
    }

    private func saveFatigueEntry(in app: XCUIApplication) {
        openNewEntry(app)
        chooseKind(.fatigue, in: app)
        setSeverity(4, in: app)
        saveEntry(app)
        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
    }

    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Frames come from the screen, so the test compares where each marker sits, top to bottom.
    private func assertInOrder(
        _ ids: [String],
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let tops = ids.map { id -> (id: String, top: CGFloat) in
            let marker = element(id, in: app)
            XCTAssertTrue(marker.waitForExistence(timeout: 10), "\(id) is not on screen", file: file, line: line)
            return (id, marker.frame.minY)
        }
        XCTAssertEqual(tops.sorted { $0.top < $1.top }.map(\.id), ids, file: file, line: line)
    }
}
