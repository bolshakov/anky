// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import XCTest

/// The hour wheel does not take hour 00 from an hour back, so the moved time stays where it was. Hour 01 or later
/// moves to a time that is still today.
@MainActor
func skipUnlessAnHourBackStaysToday() throws {
    let hour = Calendar.current.component(.hour, from: .now)
    try XCTSkipIf(
        hour < 2,
        "An hour back from 01 lands on 00, which the hour wheel does not take. Run after 02:00."
    )
}

/// Saves a Pain reading at 4 of 10 an hour back on Today, so a dose an hour back can take it as its before-reading.
@MainActor
func saveEntryAnHourBack(_ kind: EntryKind, in app: XCUIApplication) {
    openNewEntry(app)
    chooseKind(kind, in: app)
    scrollToSeveritySlider(in: app)
    setSeverity(4, in: app)
    scrollToDateRow(in: app)
    showDatePicker(in: app)
    moveHour(by: -1, in: app)
    app.buttons["date-row"].tap()
    saveEntry(app)
    XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))
}

/// Adds Zorblex with a 30 minute check-in, which leaves Log Dose open on the reading the dose now takes.
@MainActor
func addZorblexCheckingInAfterThirtyMinutes(_ app: XCUIApplication) {
    tapLogMedication(in: app)
    app.buttons["dose-add-medication"].tap()
    let name = app.textFields["medication-name"]
    XCTAssertTrue(name.waitForExistence(timeout: 10))
    name.tap()
    name.typeText("Zorblex")
    let checkIn = app.descendants(matching: .any).matching(identifier: "check-in-after").firstMatch
    XCTAssertTrue(checkIn.waitForExistence(timeout: 10))
    let save = app.buttons["medication-save"]
    for _ in 0 ..< 5 where checkIn.frame.maxY > save.frame.minY {
        app.swipeUp()
    }
    checkIn.tap()
    let thirtyMinutes = app.buttons["30 minutes"]
    XCTAssertTrue(thirtyMinutes.waitForExistence(timeout: 10))
    thirtyMinutes.tap()
    save.tap()
    XCTAssertTrue(save.waitForNonExistence(timeout: 10))
    let before = app.buttons["before-reading-row"]
    for _ in 0 ..< 5 where !before.exists || !before.isHittable {
        app.swipeUp()
    }
    XCTAssertTrue(before.waitForExistence(timeout: 10))
}

/// Moves the dose an hour back, which keeps the reading saved an hour back in its window, then saves it.
@MainActor
func saveDoseAnHourBack(in app: XCUIApplication) {
    scrollToDateRow(in: app)
    showDatePicker(in: app)
    moveHour(by: -1, in: app)
    app.buttons["date-row"].tap()
    let before = app.buttons["before-reading-row"]
    XCTAssertTrue(before.label.contains("4 of 10"), before.label)
    app.buttons["save-dose"].tap()
}

/// A dose that is waiting opens Check In from its History row.
@MainActor
func openCheckIn(_ app: XCUIApplication) {
    app.tabBars.buttons["History"].tap()
    let row = app.descendants(matching: .any)["dose-row"]
    XCTAssertTrue(row.waitForExistence(timeout: 10))
    XCTAssertTrue(identified("check-in-label", in: app).waitForExistence(timeout: 10), "dose row shows \(row.label)")
    row.tap()
    XCTAssertTrue(identified("check-in-screen", in: app).waitForExistence(timeout: 10))
}

/// The form's rows load as they scroll into view, so the Where row shows only after the form is scrolled down.
@MainActor
func scrollToBottom(of app: XCUIApplication) {
    let screen = identified("check-in-screen", in: app)
    for _ in 0 ..< 5 {
        screen.swipeUp()
    }
}

@MainActor
func identified(_ id: String, in app: XCUIApplication) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: id).firstMatch
}
