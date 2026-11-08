// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import XCTest

/// The 24 hour clock time for a moment, such as "08:15".
func clockTime(at date: Date) -> String {
    let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
    return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
}

/// Waits up to 90 seconds for the clock to pass out of the minute that `minute` names.
@MainActor
func waitForMinuteToChange(from minute: String?) {
    let deadline = Date.now.addingTimeInterval(90)
    while clockTime(at: .now) == minute, Date.now < deadline {
        Thread.sleep(forTimeInterval: 1)
    }
    XCTAssertNotEqual(clockTime(at: .now), minute)
}

/// The clock time at the end of the date row's value, which reads "<day> <time>". The day word changes with the
/// language. A 12 hour time's space before AM or PM is U+202F, so it does not split here.
private func clockTime(inRowValue value: String?) -> String? {
    value?.components(separatedBy: " ").last
}

/// The Date and time row, the element a test scrolls to, taps or checks the frame of.
@MainActor
func dateRow(in app: XCUIApplication) -> XCUIElement {
    app.buttons["date-row"]
}

/// The cell that holds the row, where a tap on the row's edge lands.
@MainActor
func dateRowCell(in app: XCUIApplication) -> XCUIElement {
    app.cells.containing(.button, identifier: "date-row").firstMatch
}

/// The wheel that the row opens below itself.
@MainActor
func dateWheel(in app: XCUIApplication) -> XCUIElement {
    app.datePickers["date-picker"]
}

/// The clock time shown on the row, such as "08:15".
@MainActor
func dateRowTime(in app: XCUIApplication) -> String? {
    clockTime(inRowValue: dateRow(in: app).value as? String)
}

/// The day shown on the row, such as "Today" or "Yesterday". The day is everything before the clock's space.
@MainActor
func dateRowDay(in app: XCUIApplication) -> String? {
    guard let value = dateRow(in: app).value as? String,
          let space = value.range(of: " ", options: .backwards)
    else {
        return nil
    }
    return String(value[..<space.lowerBound])
}

/// Scrolls the form until the row's centre is clear of the navigation bar and of the pinned Save bar. At the largest
/// size the form leaves the row out of the accessibility tree while it is off screen, below the first screen of a new
/// form or above it once a lower row is set. A row in the tree can also have its centre off screen or under the bar
/// while `isHittable` still says yes. A row that is not in the tree is looked for below first, then above.
@MainActor
func scrollToDateRow(in app: XCUIApplication) {
    let row = dateRow(in: app)
    let top = app.frame.minY + app.frame.height / 8
    func isClear() -> Bool {
        let bottom = saveBarTop(in: app)
        return row.exists && row.isHittable && (top ..< bottom).contains(row.frame.midY)
    }
    for attempt in 0 ..< 8 where !isClear() {
        let rowIsBelow = row.exists ? row.frame.midY > app.frame.midY : attempt < 3
        if rowIsBelow {
            app.swipeUp()
        } else {
            app.swipeDown()
        }
    }
}

/// Taps the date row and waits for the wheel to appear.
@MainActor
func openDateWheel(in app: XCUIApplication) {
    let row = dateRow(in: app)
    XCTAssertTrue(row.waitForExistence(timeout: 10))
    row.tap()
    XCTAssertTrue(dateWheel(in: app).waitForExistence(timeout: 10))
}

/// The hour wheel reads "00 o'clock" but takes only the bare two digits, as its possible values show.
/// Each step moves one hour, since a jump of two hours did not stick on the wheel. The wheel must be open.
@MainActor
func moveDateHour(by delta: Int, in app: XCUIApplication) {
    let hours = dateWheel(in: app).pickerWheels.element(boundBy: 1)
    XCTAssertTrue(hours.waitForExistence(timeout: 10))
    let step = delta < 0 ? -1 : 1
    for _ in 0 ..< abs(delta) {
        let current = firstNumber(in: hours.value as? String) ?? -1
        hours.adjust(toPickerWheelValue: String(format: "%02d", (current + step + 24) % 24))
    }
}

/// Opens the wheel, moves the hour back, and closes it again, so the row holds the time that many hours back.
@MainActor
func setDateTimeHoursBack(_ hours: Int, in app: XCUIApplication) {
    openDateWheel(in: app)
    moveDateHour(by: -hours, in: app)
    dateRow(in: app).tap()
}

/// Opens the wheel, moves the day back one, and closes it again. The time stays as it was.
@MainActor
func setDateToYesterday(in app: XCUIApplication) {
    openDateWheel(in: app)
    let day = dateWheel(in: app).pickerWheels.element(boundBy: 0)
    XCTAssertTrue(day.waitForExistence(timeout: 10))
    let start = day.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    start.press(
        forDuration: 0.1,
        thenDragTo: start.withOffset(CGVector(dx: 0, dy: 36)),
        withVelocity: .slow,
        thenHoldForDuration: 1
    )
    let shown = dateRowDay(in: app) ?? ""
    XCTAssertTrue(shown.hasPrefix("Yesterday"), "date row day is \(shown)")
    dateRow(in: app).tap()
}
