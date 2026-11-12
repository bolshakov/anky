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

/// Today's "Log dose" sits in the bottom pair at every text size, so the swipe loop
/// normally exits at once.
@MainActor
func tapLogMedication(in app: XCUIApplication) {
    let button = app.buttons["log-medication"]
    for _ in 0 ..< 5 where !button.isHittable {
        app.swipeUp()
    }
    XCTAssertTrue(button.isHittable)
    button.tap()
}

/// At the largest size the severity slider sits below the first screen. The pinned Save button
/// covers the bottom of the screen, so the slider must scroll above it, not merely be on screen.
/// A form leaves rows that are off screen out of the accessibility tree, so the slider may not exist yet.
@MainActor
func scrollToSeveritySlider(in app: XCUIApplication) {
    let slider = app.sliders["severity-slider"]
    let save = app.buttons["save-entry"]
    for _ in 0 ..< 5 where !slider.exists || slider.frame.maxY > save.frame.minY {
        app.swipeUp()
    }
    XCTAssertTrue(slider.exists)
    XCTAssertLessThanOrEqual(slider.frame.maxY, save.frame.minY)
}
