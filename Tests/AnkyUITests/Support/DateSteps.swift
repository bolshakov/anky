// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import XCTest

/// The 24 hour clock time for a moment, such as "8:15". The hour has no zero.
func clockTime(at date: Date) -> String {
    let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
    return String(format: "%d:%02d", parts.hour ?? 0, parts.minute ?? 0)
}

/// The date the row's date pill shows for a day, such as "3 Nov 2026". The walks and tests run in en_GB.
func dateRowDate(for date: Date) -> String {
    date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Locale(identifier: "en_GB")))
}

/// The Date and time row: the cell that holds the system compact date picker. A test scrolls to it, taps it or checks
/// its frame. The picker frames only its two pills, so the cell is what spans the row.
@MainActor
func dateRow(in app: XCUIApplication) -> XCUIElement {
    app.cells.containing(.datePicker, identifier: nil).firstMatch
}

/// The row's buttons are the picker's own button, then the date pill, then the time pill. The picker's button has a
/// localized label, so the pills are counted from the end.
@MainActor
private func pill(fromEnd offset: Int, in app: XCUIApplication) -> XCUIElement {
    let buttons = dateRow(in: app).buttons
    return buttons.element(boundBy: buttons.count - offset)
}

@MainActor
private func timePill(in app: XCUIApplication) -> XCUIElement {
    pill(fromEnd: 1, in: app)
}

@MainActor
private func datePill(in app: XCUIApplication) -> XCUIElement {
    pill(fromEnd: 2, in: app)
}

/// The clock time shown on the row, in the form `clockTime(at:)` writes. The system picker writes the 24 hour time
/// with a zero before an hour before 10, so the zero goes.
@MainActor
func dateRowTime(in app: XCUIApplication) -> String? {
    let pill = timePill(in: app)
    guard pill.exists else { return nil }
    let label = pill.label
    return label.hasPrefix("0") ? String(label.dropFirst()) : label
}

/// The date shown on the row, such as "3 Nov 2026". The picker shows a date, not a word such as "Today".
@MainActor
func dateRowDay(in app: XCUIApplication) -> String? {
    let pill = datePill(in: app)
    return pill.exists ? pill.label : nil
}

/// Scrolls the form until the row can be tapped. At the largest size the row scrolls off the top of a form once a
/// lower row is set, and a form leaves off screen rows out of the accessibility tree.
@MainActor
func scrollToDateRow(in app: XCUIApplication) {
    let row = dateRow(in: app)
    for _ in 0 ..< 5 where !row.exists || !row.isHittable {
        app.swipeDown()
    }
}

/// Taps the time pill and waits for its hour and minute wheels to appear in the popover.
@MainActor
func openDateWheel(in app: XCUIApplication) {
    let time = timePill(in: app)
    XCTAssertTrue(time.waitForExistence(timeout: 10))
    time.tap()
    XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 10))
}

/// Taps the popover's dismiss region, which closes whichever popover the picker has open. The tap lands on the
/// region's left edge, since its centre can fall on a row underneath and open that row.
@MainActor
private func closeDatePopover(in app: XCUIApplication) {
    let dismiss = app.buttons["PopoverDismissRegion"]
    XCTAssertTrue(dismiss.waitForExistence(timeout: 10))
    dismiss.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).tap()
    XCTAssertTrue(dismiss.waitForNonExistence(timeout: 10))
    XCTAssertTrue(timePill(in: app).waitForExistence(timeout: 10))
}

/// The hour wheel reads "06 o'clock" but takes only the bare two digits, as its possible values show.
/// Each step moves one hour, since a jump of two hours did not stick on the wheel. The wheel must be open.
@MainActor
func moveDateHour(by delta: Int, in app: XCUIApplication) {
    let hours = app.pickerWheels.element(boundBy: 0)
    XCTAssertTrue(hours.waitForExistence(timeout: 10))
    let step = delta < 0 ? -1 : 1
    for _ in 0 ..< abs(delta) {
        let current = firstNumber(in: hours.value as? String) ?? -1
        hours.adjust(toPickerWheelValue: String(format: "%02d", (current + step + 24) % 24))
    }
}

/// Opens the time popover, moves the hour back, and closes it again, so the row holds the time that many hours back.
@MainActor
func setDateTimeHoursBack(_ hours: Int, in app: XCUIApplication) {
    openDateWheel(in: app)
    moveDateHour(by: -hours, in: app)
    closeDatePopover(in: app)
}

/// Opens the calendar, picks yesterday, and closes it. The time stays as it was. On the first of the month yesterday is
/// in the month before, so the calendar goes back a month first.
@MainActor
func setDateToYesterday(in app: XCUIApplication) {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    let label = yesterday.formatted(
        Date.FormatStyle().weekday(.wide).day().month(.wide).locale(Locale(identifier: "en_GB"))
    )
    let pillBefore = datePill(in: app)
    XCTAssertTrue(pillBefore.waitForExistence(timeout: 10))
    pillBefore.tap()
    let day = app.buttons[label]
    if !day.exists {
        app.buttons["DatePicker.PreviousMonth"].tap()
    }
    XCTAssertTrue(day.waitForExistence(timeout: 10), "no day labelled \(label)")
    day.tap()
    closeDatePopover(in: app)
    XCTAssertEqual(dateRowDay(in: app), dateRowDate(for: yesterday))
}
