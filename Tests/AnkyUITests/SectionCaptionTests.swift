import XCTest

@MainActor
final class SectionCaptionTests: XCTestCase {
    func testSeverityCaptionSitsAboveTheSlider() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let caption = app.staticTexts.matching(identifier: "severity-caption").firstMatch
        XCTAssertTrue(caption.waitForExistence(timeout: 10))
        XCTAssertFalse(caption.label.isEmpty)
        XCTAssertLessThanOrEqual(caption.frame.maxY, app.sliders["severity-slider"].frame.minY)
    }

    func testTodayHasNoCaptionAboveTheCard() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        saveEntry(app)

        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "today-caption").firstMatch.exists)

        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.exists)
        let aboveCard = app.staticTexts.allElementsBoundByIndex.filter { $0.frame.maxY <= row.frame.minY }
        XCTAssertTrue(aboveCard.contains { $0.identifier == "today-date" })
        for text in aboveCard where text.identifier != "today-date" {
            XCTAssertTrue(navBar.frame.contains(text.frame), "\(text.frame) sits above the card")
        }
    }

    func testCardKeepsItsGapBelowTheDate() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        saveEntry(app)

        let date = app.descendants(matching: .any).matching(identifier: "today-date").firstMatch
        XCTAssertTrue(date.waitForExistence(timeout: 10))
        let row = entryRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(row.frame.minY - date.frame.maxY, 55.7, accuracy: 1)
    }
}
