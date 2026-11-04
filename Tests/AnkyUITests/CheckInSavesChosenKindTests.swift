// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class CheckInSavesChosenKindTests: XCTestCase {
    /// The kind the Check In shows is the kind saved, not the before-reading's kind. The entry lands on History at the
    /// level the person set.
    func testFatigueCheckInSavesAFatigueEntry() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.pain, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        openCheckIn(app)

        chooseKind(.fatigue, in: app)
        setSeverity(6, in: app)
        app.buttons["save-check-in"].tap()

        XCTAssertTrue(identified("check-in-screen", in: app).waitForNonExistence(timeout: 10))
        let row = app.descendants(matching: .any).matching(identifier: "entry-row-fatigue").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(rowSeverity(of: row), 6)
    }

    /// A Pain check-in saves the places its chips show as selected, and the entry's row names them.
    func testPainCheckInSavesThePlacesItShowsAsSelected() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.pain, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        openCheckIn(app)

        app.buttons["place-chip-upper"].tap()
        app.buttons["save-check-in"].tap()

        XCTAssertTrue(identified("check-in-screen", in: app).waitForNonExistence(timeout: 10))
        // The before-reading is a Pain entry too, so the row is found by the place it saved.
        let row = app.descendants(matching: .any).matching(identifier: "entry-row-pain")
            .matching(NSPredicate(format: "label CONTAINS %@", "Upper back")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
    }
}
