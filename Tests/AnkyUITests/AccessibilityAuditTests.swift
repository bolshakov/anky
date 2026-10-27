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

    /// Today empty, New Entry at the top and at the note, then Today with the row the save adds.
    private func auditEveryScreen(in app: XCUIApplication) throws {
        XCTAssertTrue(app.staticTexts["Nothing logged today"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])

        openNewEntry(app)
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])
        scrollToNoteField(in: app)
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])

        saveEntry(app)
        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))
        let row = app.descendants(matching: .any).matching(identifier: "entry-row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])
    }
}
