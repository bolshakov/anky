// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

let largestTextArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

/// The form scrolls at the largest size, so the note field is swiped into view before a check reads it.
@MainActor
func scrollToNoteField(in app: XCUIApplication) {
    let note = app.descendants(matching: .any).matching(identifier: "note-field").firstMatch
    for _ in 0 ..< 5 where !note.isHittable {
        app.swipeUp()
    }
    XCTAssertTrue(note.isHittable)
}

/// At the largest size the severity slider sits below the first screen. The pinned "Save entry"
/// covers the bottom of the screen, so the slider must scroll above it, not merely be on screen.
@MainActor
func scrollToSeveritySlider(in app: XCUIApplication) {
    let slider = app.sliders["severity-slider"]
    let save = app.buttons["save-entry"]
    for _ in 0 ..< 5 where slider.frame.maxY > save.frame.minY {
        app.swipeUp()
    }
    XCTAssertLessThanOrEqual(slider.frame.maxY, save.frame.minY)
}
