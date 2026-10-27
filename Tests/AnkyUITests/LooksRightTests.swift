import XCTest

@MainActor
final class LooksRightTests: XCTestCase {
    func testCaptureScreens() {
        continueAfterFailure = false
        let app = launchAnky()
        XCTAssertTrue(app.staticTexts["empty-today-title"].waitForExistence(timeout: 10))
        attachScreenshot(named: "looks-today-empty")

        openNewEntry(app)
        attachScreenshot(named: "looks-new-entry")
        setSeverity(10, in: app)
        attachScreenshot(named: "looks-new-entry-10")
        setSeverity(0, in: app)
        attachScreenshot(named: "looks-new-entry-0")
        setSeverity(4, in: app)
        saveEntry(app)

        openNewEntry(app)
        chooseKind("Stiffness", in: app)
        setSeverity(6, in: app)
        saveEntry(app)

        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
        let rows = app.descendants(matching: .any).matching(identifier: "entry-row")
        XCTAssertEqual(rows.count, 2)
        attachScreenshot(named: "looks-today")
    }
}
