import XCTest

@MainActor
func openNewEntry(_ app: XCUIApplication) {
    let logButton = app.buttons["Log how you feel"]
    XCTAssertTrue(logButton.waitForExistence(timeout: 10))
    logButton.tap()
    XCTAssertTrue(app.staticTexts["New Entry"].waitForExistence(timeout: 10))
}

/// XCUIElement has no increment or decrement, so each call aims one value away from the value the slider reads.
@MainActor
func setSeverity(_ level: Int, in app: XCUIApplication) {
    let slider = app.sliders["severity-slider"]
    XCTAssertTrue(slider.waitForExistence(timeout: 10))
    for _ in 0 ..< 20 {
        let current = severityValue(of: slider)
        guard current != level else { return }
        let next = current < level ? current + 1 : current - 1
        slider.adjust(toNormalizedSliderPosition: CGFloat(next) / 10)
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
