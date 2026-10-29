import XCTest

/// Checks that the 0 and 10 labels sit beyond the slider's two ends, on its row. In right-to-left the start edge is the
/// right one, so 0 goes on the right.
@MainActor
func assertEndLabels(_ app: XCUIApplication, startOnRight: Bool) {
    let slider = app.sliders["severity-slider"]
    let low = app.staticTexts["severity-low-label"]
    let high = app.staticTexts["severity-high-label"]
    XCTAssertTrue(low.waitForExistence(timeout: 10))
    XCTAssertTrue(high.exists)

    if startOnRight {
        XCTAssertGreaterThanOrEqual(low.frame.minX, slider.frame.maxX, "0 sits right of the slider")
        XCTAssertLessThanOrEqual(high.frame.maxX, slider.frame.minX, "10 sits left of the slider")
    } else {
        XCTAssertLessThanOrEqual(low.frame.maxX, slider.frame.minX, "0 sits left of the slider")
        XCTAssertGreaterThanOrEqual(high.frame.minX, slider.frame.maxX, "10 sits right of the slider")
    }
    XCTAssertEqual(low.frame.midY, slider.frame.midY, accuracy: 4, "0 sits on the slider's row")
    XCTAssertEqual(high.frame.midY, slider.frame.midY, accuracy: 4, "10 sits on the slider's row")
}
