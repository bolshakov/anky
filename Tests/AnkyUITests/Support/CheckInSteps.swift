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
func saveEntryAnHourBack(_ kind: EntryKind, places: [String] = [], in app: XCUIApplication) {
    openNewEntry(app)
    chooseKind(kind, in: app)
    for place in places {
        app.buttons["place-chip-\(place)"].tap()
    }
    scrollToSeveritySlider(in: app)
    setSeverity(4, in: app)
    scrollToDateRow(in: app)
    setDateTimeHoursBack(1, in: app)
    saveEntry(app)
    XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))
}

/// Adds Zorblex with a 30 minute check-in, which leaves Log Dose open on the reading the dose now takes.
@MainActor
func addZorblexCheckingInAfterThirtyMinutes(
    _ app: XCUIApplication,
    medication: String = "Zorblex",
    readingRow: String = "before-reading-row"
) {
    tapLogMedication(in: app)
    app.buttons["dose-add-medication"].tap()
    let name = app.textFields["medication-name"]
    XCTAssertTrue(name.waitForExistence(timeout: 10))
    name.tap()
    name.typeText(medication)
    app.typeText("\n")
    app.typeText("\n")
    XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 10))
    let form = app.descendants(matching: .any).matching(identifier: "medication-form").firstMatch
    let toggle = form.descendants(matching: .any).matching(identifier: "check-in-later").firstMatch
    XCTAssertTrue(toggle.waitForExistence(timeout: 10))
    let save = app.buttons["medication-save"]
    for _ in 0 ..< 5 where toggle.frame.maxY > save.frame.minY {
        app.swipeUp()
    }
    toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
    let menu = form.descendants(matching: .any).matching(identifier: "dose-check-in-after").firstMatch
    XCTAssertTrue(menu.waitForExistence(timeout: 10))
    for _ in 0 ..< 5 where menu.frame.maxY > save.frame.minY {
        app.swipeUp()
    }
    menu.tap()
    let thirtyMinutes = app.buttons["30 minutes"]
    XCTAssertTrue(thirtyMinutes.waitForExistence(timeout: 10))
    thirtyMinutes.tap()
    save.tap()
    XCTAssertTrue(save.waitForNonExistence(timeout: 10))
    let row = app.buttons[readingRow]
    for _ in 0 ..< 5 where !row.exists || !row.isHittable {
        app.swipeUp()
    }
    XCTAssertTrue(row.waitForExistence(timeout: 10))
}

/// Moves the dose an hour back, which keeps the reading saved an hour back in its window, then saves it. The date row
/// sits below the reading, so the form is scrolled back up to the reading, whose row leaves the tree while it is off
/// screen at the largest size.
@MainActor
func saveDoseAnHourBack(in app: XCUIApplication) {
    scrollToDateRow(in: app)
    setDateTimeHoursBack(1, in: app)
    let before = app.buttons["before-reading-row"]
    for _ in 0 ..< 5 where !before.exists || !before.isHittable {
        app.swipeDown()
    }
    XCTAssertTrue(before.waitForExistence(timeout: 10))
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

/// The form's rows load as they scroll into view, so the Where section shows only after the form is scrolled down.
@MainActor
func scrollToBottom(of app: XCUIApplication) {
    let screen = identified("check-in-screen", in: app)
    for _ in 0 ..< 5 {
        screen.swipeUp()
    }
}

/// Save check-in is the last row of the form, so the form is swiped until it is hittable.
@MainActor
func scrollToSaveCheckIn(in app: XCUIApplication) {
    let save = app.buttons["save-check-in"]
    let screen = identified("check-in-screen", in: app)
    for _ in 0 ..< 8 where !save.exists || !save.isHittable {
        screen.swipeUp()
    }
    XCTAssertTrue(save.waitForExistence(timeout: 10))
}

@MainActor
func identified(_ id: String, in app: XCUIApplication) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: id).firstMatch
}

@MainActor
func openLogDose(_ app: XCUIApplication) {
    tapLogMedication(in: app)
    XCTAssertTrue(app.buttons["dose-add-medication"].waitForExistence(timeout: 10))
}

/// Opens New Medication from Log Dose, the way a person adds a medication while logging a dose.
@MainActor
func openNewMedication(_ app: XCUIApplication) {
    openLogDose(app)
    app.buttons["dose-add-medication"].tap()
    XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))
}

/// Opens the Medications list from Log Dose, where New Medication and every Edit Medication start.
@MainActor
func openMedicationsFromLogDose(_ app: XCUIApplication) {
    app.buttons["log-dose-manage"].tap()
    XCTAssertTrue(app.buttons["medications-add"].waitForExistence(timeout: 10))
}

/// Opens New Medication from the Medications list, the second way into the form.
@MainActor
func openNewMedicationFromList(_ app: XCUIApplication) {
    app.buttons["medications-add"].tap()
    XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))
}

@MainActor
func openMedicationFromList(_ app: XCUIApplication) {
    app.buttons["medication-row"].firstMatch.tap()
    XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))
}

@MainActor
func saveNewMedication(named name: String, _ app: XCUIApplication) {
    let field = app.textFields["medication-name"]
    XCTAssertTrue(field.waitForExistence(timeout: 10))
    field.tap()
    field.typeText(name)
    app.buttons["medication-save"].tap()
    XCTAssertTrue(field.waitForNonExistence(timeout: 10))
}

/// Types the name and dismisses the keyboard, so the card below the name can be scrolled to and tapped.
@MainActor
func nameNewMedication(_ name: String, in app: XCUIApplication) {
    let field = app.textFields["medication-name"]
    XCTAssertTrue(field.waitForExistence(timeout: 10))
    field.tap()
    field.typeText(name)
    app.typeText("\n")
    app.typeText("\n")
    XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 10))
}

/// Makes the switch on when it is off, then picks the option from the menu.
@MainActor
func choose(_ option: String, in app: XCUIApplication) {
    XCTAssertTrue(checkInSwitch(in: app).waitForExistence(timeout: 10))
    if checkInSwitch(in: app).value as? String == "0" {
        turnOn(in: app)
    } else {
        scrollToCheckIn(in: app)
    }
    checkInMenu(in: app).tap()
    let item = app.buttons[option]
    XCTAssertTrue(item.waitForExistence(timeout: 10), "no menu item \(option)")
    item.tap()
    XCTAssertTrue(checkInMenu(in: app).waitForExistence(timeout: 10))
}

@MainActor
func turnOn(in app: XCUIApplication) {
    scrollToCheckIn(in: app)
    checkInSwitch(in: app).coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
    XCTAssertTrue(checkInMenu(in: app).waitForExistence(timeout: 10), "no menu after the switch went on")
}

@MainActor
func medicationForm(in app: XCUIApplication) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: "medication-form").firstMatch
}

@MainActor
func checkInSwitch(in app: XCUIApplication) -> XCUIElement {
    medicationForm(in: app).descendants(matching: .any).matching(identifier: "check-in-later").firstMatch
}

@MainActor
func checkInMenu(in app: XCUIApplication) -> XCUIElement {
    medicationForm(in: app).descendants(matching: .any).matching(identifier: "dose-check-in-after").firstMatch
}

/// The pinned Save button covers the bottom of the form, so the card must scroll above it, not merely be on screen.
/// The last row of the card is the menu when it shows, and the switch when it does not.
@MainActor
func scrollToCheckIn(in app: XCUIApplication) {
    let anchor = checkInMenu(in: app).exists ? checkInMenu(in: app) : checkInSwitch(in: app)
    XCTAssertTrue(anchor.waitForExistence(timeout: 10))
    let save = app.buttons["medication-save"]
    for _ in 0 ..< 5 where anchor.frame.maxY > save.frame.minY {
        app.swipeUp()
    }
    XCTAssertLessThanOrEqual(anchor.frame.maxY, save.frame.minY)
}
