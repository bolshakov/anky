// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
func showHistory(in app: XCUIApplication) {
    let tab = app.tabBars.buttons["History"]
    XCTAssertTrue(tab.waitForExistence(timeout: 10))
    tab.tap()
    let screen = app.descendants(matching: .any).matching(identifier: "history-screen").firstMatch
    XCTAssertTrue(screen.waitForExistence(timeout: 10))
}

/// Logs a pain entry of the level from New Entry and saves it. With `yesterday`, the time is set to yesterday first.
@MainActor
func logEntry(_ level: Int, yesterday: Bool = false, in app: XCUIApplication) {
    openNewEntry(app)
    setSeverity(level, in: app)
    if yesterday {
        moveToYesterday(in: app)
    }
    saveEntry(app)
    XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
}

/// The day headers on screen, top to bottom, such as "Today" and "Yesterday".
@MainActor
func dayHeaderLabels(in app: XCUIApplication) -> [String] {
    app.descendants(matching: .any).matching(identifier: "day-header").allElementsBoundByIndex.map(\.label)
}

/// Drags the row left by about a third of its width. That reveals the trailing actions without a full swipe.
@MainActor
func partSwipeRow(_ row: XCUIElement) {
    let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
    start.press(forDuration: 0.05, thenDragTo: row.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.5)))
}

/// Swipes the row from right to left until its Delete action shows, then taps Delete.
@MainActor
func tapDeleteOnRow(_ row: XCUIElement, in app: XCUIApplication) {
    partSwipeRow(row)
    let delete = app.buttons["history-delete"].firstMatch
    XCTAssertTrue(delete.waitForExistence(timeout: 10))
    delete.tap()
}
