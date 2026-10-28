import XCTest

@MainActor
func openNewEntry(_ app: XCUIApplication) {
    let logButton = app.buttons["log-entry"]
    XCTAssertTrue(logButton.waitForExistence(timeout: 10))
    logButton.tap()
    XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForExistence(timeout: 10))
}

/// XCUIElement has no increment or decrement, so each call drives the slider by position. A short drag from a
/// nearby value can settle one step off, so a close target first goes to the far end of the track.
@MainActor
func setSeverity(_ level: Int, in app: XCUIApplication) {
    let slider = app.sliders["severity-slider"]
    XCTAssertTrue(slider.waitForExistence(timeout: 10))
    for _ in 0 ..< 20 {
        let current = severityLevel(of: slider) ?? -1
        guard current != level else { return }
        if abs(current - level) <= 2 {
            slider.adjust(toNormalizedSliderPosition: level >= 5 ? 0 : 1)
            guard severityLevel(of: slider) != level else { return }
        }
        slider.adjust(toNormalizedSliderPosition: CGFloat(level) / 10)
    }
    XCTFail("the severity slider did not reach \(level)")
}

@MainActor
func saveEntry(_ app: XCUIApplication) {
    let saveButton = app.buttons["save-entry"]
    XCTAssertTrue(saveButton.waitForExistence(timeout: 10))
    saveButton.tap()
}

@MainActor
func severityLevel(of slider: XCUIElement) -> Int? {
    leadingNumber(in: slider.value as? String)
}
