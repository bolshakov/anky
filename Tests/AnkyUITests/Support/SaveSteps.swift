// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import XCTest

/// The time is read from the date row before the save, since the saved row's label has no digits in double-length
/// text. It falls in the minute before or after the save.
@MainActor
func saveFourOfTen(in app: XCUIApplication) {
    let before = clockTime(at: .now)
    openNewEntry(app)
    setSeverity(4, in: app)
    let shown = dateRowTime(in: app)
    saveEntry(app)
    let after = clockTime(at: .now)
    XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
    XCTAssertTrue([before, after].contains(shown ?? ""), "date row time is \(shown ?? "nil")")
}

@MainActor
func saveFatigueEntry(in app: XCUIApplication) {
    openNewEntry(app)
    chooseKind(.fatigue, in: app)
    setSeverity(4, in: app)
    saveEntry(app)
    XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
}
