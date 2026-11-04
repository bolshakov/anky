// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class CheckInWhereChipsTests: XCTestCase {
    /// A Pain reading with no places before it, so the chips start with none selected.
    func testAPainCheckInWithNoEarlierPlacesShowsTheChipsWithNoneSelected() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        setUpWaitingPainDose(in: app)
        openCheckIn(app)

        XCTAssertTrue(identified("where-section", in: app).waitForExistence(timeout: 10))
        let neck = app.buttons["place-chip-neck"]
        XCTAssertTrue(neck.waitForExistence(timeout: 10))
        XCTAssertFalse(neck.isSelected)
        XCTAssertEqual(identified("more-places", in: app).value as? String, "None")
    }

    /// The earlier reading's places start selected on their chips, and the chips not among them stay off.
    func testAPainCheckInStartsWithTheEarlierReadingsPlacesSelected() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        setUpWaitingPainDose(in: app, places: ["neck", "lower"])
        openCheckIn(app)

        XCTAssertTrue(identified("where-section", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(isSelected(app.buttons["place-chip-neck"]))
        XCTAssertTrue(isSelected(app.buttons["place-chip-lower"]))
        XCTAssertFalse(app.buttons["place-chip-upper"].isSelected)
    }

    /// Fatigue asks no place, so its Check In has no Where section. Pain again brings back the places the draft kept.
    func testFatigueHidesThePlaceChipsAndPainShowsThePlacesKept() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        setUpWaitingPainDose(in: app)
        openCheckIn(app)

        app.buttons["place-chip-neck"].tap()
        XCTAssertTrue(isSelected(app.buttons["place-chip-neck"]))

        chooseKind(.fatigue, in: app)
        XCTAssertTrue(identified("where-section", in: app).waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.buttons["place-chip-neck"].waitForNonExistence(timeout: 10))

        chooseKind(.pain, in: app)
        let neck = app.buttons["place-chip-neck"]
        XCTAssertTrue(neck.waitForExistence(timeout: 10))
        XCTAssertTrue(isSelected(neck))
    }

    /// More places opens the place list on the places the draft holds, and Back returns with the same chips selected.
    func testMorePlacesOpensThePlaceListAndBackKeepsTheSelection() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        setUpWaitingPainDose(in: app)
        openCheckIn(app)

        app.buttons["place-chip-neck"].tap()
        XCTAssertTrue(isSelected(app.buttons["place-chip-neck"]))

        identified("more-places", in: app).tap()
        XCTAssertTrue(identified("place-row-neck", in: app).waitForExistence(timeout: 10))
        app.buttons["BackButton"].tap()

        XCTAssertTrue(identified("check-in-screen", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(isSelected(app.buttons["place-chip-neck"]))
    }

    /// A Pain reading at 4 of 10 an hour back with the given places, and a Zorblex dose an hour back that takes it, so
    /// Today holds a waiting dose.
    private func setUpWaitingPainDose(in app: XCUIApplication, places: [String] = []) {
        saveEntryAnHourBack(.pain, places: places, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
    }

    private func isSelected(_ element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "selected == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: 5) == .completed
    }
}
