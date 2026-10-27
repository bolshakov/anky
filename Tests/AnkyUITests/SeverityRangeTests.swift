import XCTest

@MainActor
final class SeverityRangeTests: XCTestCase {
    func testSliderShowsEndLabelsAndTicks() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let slider = app.sliders["severity-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        let low = app.staticTexts["0"]
        let high = app.staticTexts["10"]
        XCTAssertTrue(low.waitForExistence(timeout: 10))
        XCTAssertTrue(high.exists)

        XCTAssertLessThanOrEqual(low.frame.maxX, slider.frame.minX, "0 sits left of the slider")
        XCTAssertGreaterThanOrEqual(high.frame.minX, slider.frame.maxX, "10 sits right of the slider")
        XCTAssertEqual(low.frame.midY, slider.frame.midY, accuracy: 4, "0 sits on the slider's row")
        XCTAssertEqual(high.frame.midY, slider.frame.midY, accuracy: 4, "10 sits on the slider's row")
        attachScreenshot(named: "severity-range")
    }
}
