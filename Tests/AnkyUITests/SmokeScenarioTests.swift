// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// One launch walks the screens a pull request must keep working, each step living on what the step before saved. The
/// isolated tests that cover the same ground run each night.
@MainActor
final class SmokeScenarioTests: XCTestCase {
    func testSmokeScenario() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)

        XCTContext.runActivity(named: "First launch: empty state, then New Entry without chips") { _ in
            checkEmptyStateAndFirstNewEntry(in: app)
        }
        XCTContext.runActivity(named: "A saved entry is the one row on Today") { _ in
            saveFourOfTen(in: app)
            expectTodayRows(count: 1, in: app)
            attachScreenshot(named: "save-entry-on-today")
        }
        XCTContext.runActivity(named: "A recent entry: New Entry starts with the chips") { _ in
            checkNewEntryWithChips(in: app)
        }
        XCTContext.runActivity(named: "Edit Entry for fatigue: no where, note last") { _ in
            saveFatigueEntry(in: app)
            expectTodayRows(count: 2, in: app)
            checkEditFatigue(in: app)
        }
        XCTContext.runActivity(named: "Both entries survive a relaunch") { _ in
            app.terminate()
            let relaunched = launchAnky(folder: folder)
            expectTodayRows(count: 2, in: relaunched)
            attachScreenshot(named: "entries-survive-relaunch")
        }
    }

    private func checkEmptyStateAndFirstNewEntry(in app: XCUIApplication) {
        expectEmptyState(in: app)
        openNewEntry(app)
        XCTAssertFalse(element("recent-chips", in: app).exists)
        assertInOrder(["kind-picker", "severity-label", "where-label", "date row", "note-field"], in: app)
        attachScreenshot(named: "new-entry")
        cancelNewEntry(in: app)
    }

    private func checkNewEntryWithChips(in app: XCUIApplication) {
        openNewEntry(app)
        assertInOrder(
            ["recent-chips", "kind-picker", "severity-label", "where-label", "date row", "note-field"],
            in: app
        )
        cancelNewEntry(in: app)
    }

    private func checkEditFatigue(in app: XCUIApplication) {
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
        saveEntry(app)
        XCTAssertTrue(screen.waitForNonExistence(timeout: 10))
    }

    private func expectEmptyState(in app: XCUIApplication) {
        XCTAssertTrue(app.descendants(matching: .any)["today-screen"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["today-date"].exists)
        XCTAssertTrue(app.staticTexts["empty-today"].exists)
        XCTAssertEqual(entryRows(in: app).count, 0)
        XCTAssertFalse(app.staticTexts["Levels are 0 to 10. Everything stays on this iPhone."].exists)
        let addButton = app.buttons["add-menu"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(addButton.frame.height, 44)
        attachScreenshot(named: "empty-state")
    }

    private func cancelNewEntry(in app: XCUIApplication) {
        let cancel = app.buttons["cancel-entry"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 10))
        cancel.tap()
        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.buttons["add-menu"].exists)
    }

    private func expectTodayRows(count: Int, in app: XCUIApplication) {
        let rows = entryRows(in: app)
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(rows.count, count)
        for index in 0 ..< count {
            XCTAssertEqual(rowSeverity(of: rows.element(boundBy: index)), 4)
        }
    }
}
