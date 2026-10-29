import XCTest

@MainActor
final class SeverityMirrorTests: XCTestCase {
    func testRightToLeftEndsAndTapsMirror() {
        continueAfterFailure = false
        let app = launchAnky(presentation: .rightToLeft)
        openNewEntry(app)

        let slider = app.sliders["severity-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        assertEndLabels(app, startOnRight: true)
        XCTAssertEqual(severityLevel(of: slider), 0)
        attachScreenshot(named: "new-entry-rtl-0")

        tap(slider, atNormalizedPosition: 0.02)
        XCTAssertEqual(severityLevel(of: slider), 10)
        attachScreenshot(named: "new-entry-rtl-10")

        tap(slider, atNormalizedPosition: 0.7)
        XCTAssertEqual(severityLevel(of: slider), 3)
        attachScreenshot(named: "new-entry-rtl-3")

        tap(slider, atNormalizedPosition: 0.98)
        XCTAssertEqual(severityLevel(of: slider), 0)
    }

    private func tap(_ slider: XCUIElement, atNormalizedPosition position: CGFloat) {
        slider.coordinate(withNormalizedOffset: CGVector(dx: position, dy: 0.5)).tap()
    }
}
