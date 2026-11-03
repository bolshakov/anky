// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import XCTest

/// The 24 hour clock time for a moment, such as "8:15". The hour has no zero.
func clockTime(at date: Date) -> String {
    let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
    return String(format: "%d:%02d", parts.hour ?? 0, parts.minute ?? 0)
}

/// The clock time at the end of the date row's value, which reads "<day> <time>". The day word changes with the
/// language. A 12 hour time's space before AM or PM is U+202F, so it does not split here.
func clockTime(inRowValue value: String?) -> String? {
    value?.components(separatedBy: " ").last
}

/// Taps the date row and waits for the wheel to appear.
@MainActor
func showDatePicker(in app: XCUIApplication) {
    let row = app.buttons["date-row"]
    XCTAssertTrue(row.waitForExistence(timeout: 10))
    row.tap()
    XCTAssertTrue(app.datePickers["date-picker"].waitForExistence(timeout: 10))
}

/// Moves the day wheel back one day. A swipe or a quick drag flings the wheel by many days, so the drag is slow and
/// holds at its end until the wheel stops.
@MainActor
func moveToYesterday(in app: XCUIApplication) {
    showDatePicker(in: app)
    let day = app.datePickers["date-picker"].pickerWheels.element(boundBy: 0)
    XCTAssertTrue(day.waitForExistence(timeout: 10))
    let start = day.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    start.press(
        forDuration: 0.1,
        thenDragTo: start.withOffset(CGVector(dx: 0, dy: 36)),
        withVelocity: .slow,
        thenHoldForDuration: 1
    )
    let shown = app.buttons["date-row"].value as? String ?? ""
    XCTAssertTrue(shown.hasPrefix("Yesterday"), "date-row is \(shown)")
}

/// The hour wheel reads "00 o'clock" but takes only the bare two digits, as its possible values show.
/// Each step moves one hour, since a jump of two hours did not stick on the wheel.
@MainActor
func moveHour(by delta: Int, in app: XCUIApplication) {
    let hours = app.datePickers["date-picker"].pickerWheels.element(boundBy: 1)
    XCTAssertTrue(hours.waitForExistence(timeout: 10))
    let step = delta < 0 ? -1 : 1
    for _ in 0 ..< abs(delta) {
        let current = firstNumber(in: hours.value as? String) ?? -1
        hours.adjust(toPickerWheelValue: String(format: "%02d", (current + step + 24) % 24))
    }
}
