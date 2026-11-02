// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class SeverityRangeTests: XCTestCase {
    func testSliderShowsEndLabelsAndTicks() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        XCTAssertTrue(app.sliders["severity-slider"].waitForExistence(timeout: 10))
        attachScreenshot(named: "severity-range")
    }

    func testSliderIsAtLeast44PointsTallAtTheLargestText() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        openNewEntry(app)

        let slider = app.sliders["severity-slider"]
        scrollToSeveritySlider(in: app)
        XCTAssertGreaterThanOrEqual(slider.frame.height, 44)
        attachScreenshot(named: "severity-large-text")
    }
}
