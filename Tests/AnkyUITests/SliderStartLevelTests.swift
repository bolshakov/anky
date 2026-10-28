import XCTest

@MainActor
final class SliderStartLevelTests: XCTestCase {
    func testOpensAtZeroThenAtLastLevel() {
        continueAfterFailure = false
        let app = launchAnky()

        openNewEntry(app)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 0)
        attachScreenshot(named: "slider-start-first")

        setSeverity(6, in: app)
        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))

        openNewEntry(app)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 6)
        attachScreenshot(named: "slider-start-after-six")
    }
}
