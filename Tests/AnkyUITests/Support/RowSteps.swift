// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// Today's entry rows. Each id is `entry-row-<kind raw value>`, so the prefix finds a row of any kind.
@MainActor
func entryRows(in app: XCUIApplication) -> XCUIElementQuery {
    app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "entry-row"))
}

/// The kind's title is a word that changes with the language, so the row's time stands in for its label. An entry
/// row speaks its kind, its level, then its time.
func rowTime(of row: XCUIElement) -> String {
    row.label.components(separatedBy: ", ")[2]
}

/// A dose row speaks its title, then its time, then the word Dose.
func doseRowTime(of label: String) -> String {
    label.components(separatedBy: ". ")[1]
}

func rowSeverity(of row: XCUIElement) -> Int? {
    firstNumber(in: row.label.components(separatedBy: ", ")[1])
}
