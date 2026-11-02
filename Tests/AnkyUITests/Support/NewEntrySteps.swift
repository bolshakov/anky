// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// The entry screen is a `Form` and no longer a scroll view, so lookups of it go through this one place.
@MainActor
func entryScreen(_ app: XCUIApplication, id: String = "new-entry-screen") -> XCUIElement {
    app.collectionViews[id]
}

@MainActor
func openNewEntry(_ app: XCUIApplication) {
    let logButton = app.buttons["log-entry"]
    XCTAssertTrue(logButton.waitForExistence(timeout: 10))
    logButton.tap()
    XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForExistence(timeout: 10))
}

/// XCUIElement has no increment or decrement, so each call drives the slider by position. A short drag from a
/// nearby value can settle one step off, so a close target first goes to the far end of the track. The position counts
/// from the screen's left, so in right-to-left level 0 is on the right.
@MainActor
func setSeverity(_ level: Int, in app: XCUIApplication) {
    let slider = app.sliders["severity-slider"]
    XCTAssertTrue(slider.waitForExistence(timeout: 10))
    liftAboveSaveBar(slider, in: app)
    // Reads the direction from the level at the screen's left edge, which needs no end label.
    slider.adjust(toNormalizedSliderPosition: 0)
    let startOnRight = severityLevel(of: slider) == 10
    func screenPosition(_ value: Int) -> CGFloat {
        let fromStart = CGFloat(value) / 10
        return startOnRight ? 1 - fromStart : fromStart
    }
    for _ in 0 ..< 20 {
        let current = severityLevel(of: slider) ?? -1
        guard current != level else { return }
        if abs(current - level) <= 2 {
            slider.adjust(toNormalizedSliderPosition: screenPosition(level >= 5 ? 0 : 10))
            guard severityLevel(of: slider) != level else { return }
        }
        slider.adjust(toNormalizedSliderPosition: screenPosition(level))
    }
    XCTFail("the severity slider did not reach \(level)")
}

/// The pinned Save bar covers the bottom of the form, and a drag that starts under it taps Save, which saves the entry.
@MainActor
private func liftAboveSaveBar(_ slider: XCUIElement, in app: XCUIApplication) {
    for _ in 0 ..< 3 where slider.frame.midY > app.frame.midY {
        app.swipeUp(velocity: .slow)
    }
}

@MainActor
func saveEntry(_ app: XCUIApplication) {
    let saveButton = app.buttons["save-entry"]
    XCTAssertTrue(saveButton.waitForExistence(timeout: 10))
    saveButton.tap()
}

@MainActor
func severityLevel(of slider: XCUIElement) -> Int? {
    firstNumber(in: slider.value as? String)
}
