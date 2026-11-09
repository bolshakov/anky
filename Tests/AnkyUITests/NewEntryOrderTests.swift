// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import XCTest

@MainActor
final class NewEntryOrderTests: XCTestCase {
    func testNewEntryWithRecentStartsWithChipsThenKind() {
        continueAfterFailure = false
        let app = launchAnky()
        savePainInLeftKnee(in: app)

        openNewEntry(app)
        assertInOrder(
            ["recent-chips", "kind-picker", "severity-label", "where-label", "date row", "note-field"],
            in: app
        )
    }

    func testNewEntryWithoutRecentStartsWithKind() {
        continueAfterFailure = false
        let app = launchAnky()

        openNewEntry(app)
        XCTAssertFalse(element("recent-chips", in: app).exists)
        assertInOrder(["kind-picker", "severity-label", "where-label", "date row", "note-field"], in: app)
    }

    func testRecentChipFillsKindPlacesAndSeverity() {
        continueAfterFailure = false
        let app = launchAnky()
        savePainInLeftKnee(in: app)

        openNewEntry(app)
        setSeverity(9, in: app)
        // Lifting the slider scrolls the form, which takes the chips row, its first section, out of the tree.
        let chip = app.buttons["recent-chip-0"]
        for _ in 0 ..< 3 where !chip.exists {
            entryScreen(app).swipeDown()
        }
        XCTAssertTrue(chip.waitForExistence(timeout: 10))
        chip.tap()
        XCTAssertTrue(kindSegment(.pain, in: app).isSelected)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 4)
        let more = app.buttons["more-places"]
        XCTAssertTrue(more.waitForExistence(timeout: 10))
        XCTAssertTrue((more.value as? String ?? "").contains("Left knee"), "more-places is \(more.value ?? "")")
    }

    func testEditFatigueHasNoWhereAndNoteLast() {
        continueAfterFailure = false
        let app = launchAnky()
        saveFatigueEntry(in: app)

        let row = app.buttons["entry-row-fatigue"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        let screen = entryScreen(app, id: "edit-entry-screen")
        XCTAssertTrue(screen.waitForExistence(timeout: 10))
        XCTAssertFalse(element("where-label", in: app).exists)

        let note = element("note-field", in: app)
        for _ in 0 ..< 3 where !note.exists {
            screen.swipeUp()
        }
        assertInOrder(["kind-picker", "severity-label", "date row", "note-field"], in: app)
        XCTAssertFalse(element("delete-entry", in: app).exists)
    }

    /// Left knee is not a default chip, so it shows in the More places value, where the test can read it.
    private func savePainInLeftKnee(in app: XCUIApplication) {
        openNewEntry(app)
        chooseKind(.pain, in: app)
        setSeverity(4, in: app)
        app.buttons["more-places"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("Knee")
        let leftKnee = app.buttons["place-knee_l"]
        XCTAssertTrue(leftKnee.waitForExistence(timeout: 10))
        // The row's button is accessibility-only, so it never counts as hittable, while a finger reaches it.
        leftKnee.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let done = app.buttons["done-places"]
        XCTAssertEqual(done.label, "Done, 1 place", "the tap did not choose the Left knee row")
        done.tap()
        saveEntry(app)
        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
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
            let found = marker(id, in: app)
            XCTAssertTrue(found.waitForExistence(timeout: 10), "\(id) is not on screen", file: file, line: line)
            return (id, found.frame.minY)
        }
        XCTAssertEqual(tops.sorted { $0.top < $1.top }.map(\.id), ids, file: file, line: line)
    }

    /// The date row is reached through its helper, so its name here is not an id.
    private func marker(_ name: String, in app: XCUIApplication) -> XCUIElement {
        name == "date row" ? dateRow(in: app) : element(name, in: app)
    }
}
