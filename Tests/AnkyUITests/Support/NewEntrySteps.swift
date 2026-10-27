import XCTest

@MainActor
func openNewEntry(_ app: XCUIApplication) {
    let logButton = app.buttons["Log how you feel"]
    XCTAssertTrue(logButton.waitForExistence(timeout: 10))
    logButton.tap()
    XCTAssertTrue(app.staticTexts["New Entry"].waitForExistence(timeout: 10))
}

/// XCUIElement has no increment or decrement, so each call drives the slider by position. A short drag from a
/// nearby value can settle one step off, so a close target first goes to the far end of the track.
@MainActor
func setSeverity(_ level: Int, in app: XCUIApplication) {
    let slider = app.sliders["severity-slider"]
    XCTAssertTrue(slider.waitForExistence(timeout: 10))
    for _ in 0 ..< 20 {
        let current = severityValue(of: slider)
        guard current != level else { return }
        if abs(current - level) <= 2 {
            slider.adjust(toNormalizedSliderPosition: level >= 5 ? 0 : 1)
            guard severityValue(of: slider) != level else { return }
        }
        slider.adjust(toNormalizedSliderPosition: CGFloat(level) / 10)
    }
    XCTFail("the severity slider did not reach \(level)")
}

@MainActor
func saveEntry(_ app: XCUIApplication) {
    let saveButton = app.buttons["Save entry"]
    XCTAssertTrue(saveButton.waitForExistence(timeout: 10))
    saveButton.tap()
}

@MainActor
private func severityValue(of slider: XCUIElement) -> Int {
    let text = slider.value as? String ?? ""
    return Int(text.prefix { $0.isNumber }) ?? -1
}
