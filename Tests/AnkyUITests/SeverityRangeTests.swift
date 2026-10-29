import XCTest

@MainActor
final class SeverityRangeTests: XCTestCase {
    func testSliderShowsEndLabelsAndTicks() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        XCTAssertTrue(app.sliders["severity-slider"].waitForExistence(timeout: 10))
        assertEndLabels(app, startOnRight: false)
        attachScreenshot(named: "severity-range")
    }
}
