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

/// Swipes the row from right to left until its Delete action shows, then taps Delete.
@MainActor
func tapDeleteOnRow(_ row: XCUIElement, in app: XCUIApplication) {
    row.swipeLeft()
    let delete = app.buttons["history-delete"].firstMatch
    XCTAssertTrue(delete.waitForExistence(timeout: 10))
    delete.tap()
}
