import Foundation
import XCTest

/// The date row's value for a moment, such as "Today, 08:15".
func dateRowValue(at date: Date) -> String {
    let style = Date.FormatStyle(date: .omitted, time: .shortened).locale(Locale(identifier: "en_GB"))
    return "Today, \(date.formatted(style))"
}

/// Taps the date row and waits for the wheel to appear.
@MainActor
func showDatePicker(in app: XCUIApplication) {
    let row = app.buttons["date-row"]
    XCTAssertTrue(row.waitForExistence(timeout: 10))
    row.tap()
    XCTAssertTrue(app.datePickers["date-picker"].waitForExistence(timeout: 10))
}

/// The hour wheel reads "00 o'clock" but takes only the bare two digits, as its possible values show.
@MainActor
func moveHour(by delta: Int, in app: XCUIApplication) {
    let hours = app.datePickers["date-picker"].pickerWheels.element(boundBy: 1)
    XCTAssertTrue(hours.waitForExistence(timeout: 10))
    let current = Int((hours.value as? String ?? "").prefix { $0.isNumber }) ?? -1
    let next = (current + delta + 24) % 24
    hours.adjust(toPickerWheelValue: String(format: "%02d", next))
}
