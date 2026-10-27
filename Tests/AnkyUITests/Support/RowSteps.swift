import XCTest

/// Today's entry rows. Each id is `entry-row-<kind raw value>`, so the prefix finds a row of any kind.
@MainActor
func entryRows(in app: XCUIApplication) -> XCUIElementQuery {
    app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "entry-row"))
}

/// The kind's title is a word that changes with the language, so the row's time stands in for its label.
func rowTime(of row: XCUIElement) -> String {
    String(row.label.prefix { $0 != "," })
}

func rowSeverity(of row: XCUIElement) -> Int? {
    leadingNumber(in: row.label.components(separatedBy: ", ").last)
}
