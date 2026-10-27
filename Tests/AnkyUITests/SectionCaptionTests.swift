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

    func testTodayHasNoCaptionAboveTheCard() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        saveEntry(app)

        let row = app.descendants(matching: .any).matching(identifier: "entry-row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "today-caption").firstMatch.exists)

        let navBar = app.navigationBars["Today"]
        XCTAssertTrue(navBar.exists)
        let todayTexts = app.staticTexts.matching(NSPredicate(format: "label == %@", "Today")).allElementsBoundByIndex
        XCTAssertFalse(todayTexts.isEmpty)
        for text in todayTexts {
            XCTAssertTrue(navBar.frame.contains(text.frame))
        }
    }

    func testCardKeepsItsGapBelowTheDate() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        saveEntry(app)

        let date = app.descendants(matching: .any).matching(identifier: "today-date").firstMatch
        XCTAssertTrue(date.waitForExistence(timeout: 10))
        let row = app.descendants(matching: .any).matching(identifier: "entry-row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(row.frame.minY - date.frame.maxY, 55.7, accuracy: 1)
    }
}
