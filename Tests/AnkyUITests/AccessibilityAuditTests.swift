import XCTest

@MainActor
final class AccessibilityAuditTests: XCTestCase {
    func testAuditAtDefaultSize() throws {
        continueAfterFailure = false
        try auditEveryScreen(in: launchAnky())
    }

    func testAuditAtLargestSize() throws {
        continueAfterFailure = false
        try auditEveryScreen(in: launchAnky(arguments: largestTextArguments))
    }

    func testAuditAtLargestNonAccessibilitySize() throws {
        continueAfterFailure = false
        let arguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"]
        try auditEveryScreen(in: launchAnky(arguments: arguments))
    }

    /// Today empty, New Entry at the top and at the note, then Today with the row the save adds.
    private func auditEveryScreen(in app: XCUIApplication) throws {
        XCTAssertTrue(app.staticTexts["empty-today"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])

        openNewEntry(app)
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])
        scrollToNoteField(in: app)
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])

        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])
    }
}
