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
/// Each step moves one hour, since a jump of two hours did not stick on the wheel.
@MainActor
func moveHour(by delta: Int, in app: XCUIApplication) {
    let hours = app.datePickers["date-picker"].pickerWheels.element(boundBy: 1)
    XCTAssertTrue(hours.waitForExistence(timeout: 10))
    let step = delta < 0 ? -1 : 1
    for _ in 0 ..< abs(delta) {
        let current = Int((hours.value as? String ?? "").prefix { $0.isNumber }) ?? -1
        hours.adjust(toPickerWheelValue: String(format: "%02d", (current + step + 24) % 24))
    }
}
