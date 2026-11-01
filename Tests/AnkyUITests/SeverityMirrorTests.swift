// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class SeverityMirrorTests: XCTestCase {
    func testRightToLeftKnobStartsAtTheRightAndDragsByLevel() {
        continueAfterFailure = false
        let app = launchAnky(presentation: .rightToLeft)
        openNewEntry(app)

        let slider = app.sliders["severity-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        XCTAssertEqual(severityLevel(of: slider), 0)
        attachScreenshot(named: "new-entry-rtl-0")

        drag(slider, fromLevel: 0, toLevel: 7)
        XCTAssertEqual(severityLevel(of: slider), 7)
        attachScreenshot(named: "new-entry-rtl-7")

        drag(slider, fromLevel: 7, toLevel: 10)
        XCTAssertEqual(severityLevel(of: slider), 10)
    }

    private func drag(_ slider: XCUIElement, fromLevel: Int, toLevel: Int) {
        let start = knobCoordinate(of: slider, level: fromLevel, rightToLeft: true)
        let end = knobCoordinate(of: slider, level: toLevel, rightToLeft: true)
        start.press(forDuration: 0.5, thenDragTo: end)
    }
}
