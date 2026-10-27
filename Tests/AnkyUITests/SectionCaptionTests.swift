import XCTest

@MainActor
final class SectionCaptionTests: XCTestCase {
    func testSeverityCaptionSitsAboveTheSlider() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let caption = app.staticTexts.matching(identifier: "severity-caption").firstMatch
        XCTAssertTrue(caption.waitForExistence(timeout: 10))
        XCTAssertEqual(caption.label, "Severity")
        XCTAssertLessThanOrEqual(caption.frame.maxY, app.sliders["severity-slider"].frame.minY)
    }

    func testTodayCaptionSitsAboveTheEntries() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        saveEntry(app)

        let caption = app.staticTexts.matching(identifier: "today-caption").firstMatch
        XCTAssertTrue(caption.waitForExistence(timeout: 10))
        XCTAssertEqual(caption.label, "Today")
        let row = app.descendants(matching: .any).matching(identifier: "entry-row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertLessThanOrEqual(caption.frame.maxY, row.frame.minY)
    }
}
