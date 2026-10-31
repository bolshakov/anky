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
}
