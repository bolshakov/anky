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
