import XCTest

@MainActor
final class SliderStartLevelTests: XCTestCase {
    func testOpensAtZeroThenAtLastLevel() {
        continueAfterFailure = false
        let app = launchAnky()

        openNewEntry(app)
        XCTAssertEqual(severityValue(in: app), "0 of 10")
        attachScreenshot(named: "slider-start-first")

        setSeverity(6, in: app)
        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))

        openNewEntry(app)
        XCTAssertEqual(severityValue(in: app), "6 of 10")
        attachScreenshot(named: "slider-start-after-six")
    }

    private func severityValue(in app: XCUIApplication) -> String? {
        app.sliders["severity-slider"].value as? String
    }
}
