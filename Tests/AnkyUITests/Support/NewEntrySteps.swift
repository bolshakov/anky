// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// The entry screen is a `Form` and no longer a scroll view, so lookups of it go through this one place.
@MainActor
func entryScreen(_ app: XCUIApplication, id: String = "new-entry-screen") -> XCUIElement {
    app.collectionViews[id]
}

@MainActor
func openNewEntry(_ app: XCUIApplication) {
    addMenuItem("log-entry", in: app).tap()
    XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForExistence(timeout: 10))
}

/// XCUIElement has no increment or decrement, so each call moves the slider by position. In right-to-left
/// `adjust(toNormalizedSliderPosition:)` presses where it expects a left-to-right knob and cannot move a slider that
/// sits at level 0, so there the knob is dragged from its current level.
@MainActor
func setSeverity(_ level: Int, in app: XCUIApplication) {
    let slider = app.sliders["severity-slider"]
    XCTAssertTrue(slider.waitForExistence(timeout: 10))
    liftAboveSaveBar(slider, in: app)
    if isRightToLeft(app) {
        dragSeverityKnob(slider, to: level)
    } else {
        adjustSeverity(slider, to: level)
    }
}

/// A short move from a nearby value can settle one step off, so a close target first goes to the far end of the track.
@MainActor
private func adjustSeverity(_ slider: XCUIElement, to level: Int) {
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

/// A plain press and drag overshoots a short move by a step, and the next drag back overshoots the other way, so the
/// drag is slow and holds at its end to let the slider settle.
@MainActor
private func dragSeverityKnob(_ slider: XCUIElement, to level: Int) {
    for _ in 0 ..< 20 {
        guard let current = severityLevel(of: slider) else { break }
        guard current != level else { return }
        let from = knobCoordinate(of: slider, level: current, rightToLeft: true)
        let to = knobCoordinate(of: slider, level: level, rightToLeft: true)
        from.press(forDuration: 0.5, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.5)
    }
    XCTFail("the severity slider did not reach \(level)")
}

private func isRightToLeft(_ app: XCUIApplication) -> Bool {
    Presentation.rightToLeft.launchArguments.allSatisfy(app.launchArguments.contains)
}

/// The top edge of the pinned Save bar of whichever form is open, or the screen's bottom when none shows. `isHittable`
/// does not see the bar covering an element, so a step compares frames with this.
@MainActor
func saveBarTop(in app: XCUIApplication) -> CGFloat {
    let bars = ["save-entry", "save-dose", "save-check-in", "save-dose-changes"].map { app.buttons[$0] }
        .filter(\.exists)
    return bars.map(\.frame.minY).min() ?? app.frame.maxY
}

/// The pinned Save bar covers the bottom of the form, and a drag that starts under it taps Save, which saves the entry.
/// A slider the bar leaves clear stays where it is: at the largest size the lift flings it off the top of the form.
@MainActor
private func liftAboveSaveBar(_ slider: XCUIElement, in app: XCUIApplication) {
    let margin = 0.02
    let from = app.coordinate(withNormalizedOffset: CGVector(dx: margin, dy: 0.6))
    let to = app.coordinate(withNormalizedOffset: CGVector(dx: margin, dy: 0.4))
    for _ in 0 ..< 6 where slider.exists && slider.frame.maxY > saveBarTop(in: app) {
        from.press(forDuration: 0.1, thenDragTo: to)
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

/// Opens the More menu on Edit Entry and taps its Delete entry item, which opens the confirmation alert.
@MainActor
func chooseDeleteEntry(in app: XCUIApplication) {
    let more = app.buttons["entry-more"]
    XCTAssertTrue(more.waitForExistence(timeout: 10))
    more.tap()
    let delete = app.buttons["Delete entry"]
    XCTAssertTrue(delete.waitForExistence(timeout: 10))
    delete.tap()
}
