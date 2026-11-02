// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class PlacesRowTests: XCTestCase {
    private let spineAndSacroiliacRaw = ["neck", "upper", "lower", "tail", "si_l", "si_r"]

    func testSpineAndSacroiliacRowsAreAtLeastFortyFourPointsTall() {
        continueAfterFailure = false
        let app = launchAnky()
        openPlaces(in: app)

        for raw in spineAndSacroiliacRaw {
            let row = placeRow(raw, in: app)
            XCTAssertTrue(row.waitForExistence(timeout: 10), "place-row-\(raw) is on screen")
            XCTAssertGreaterThanOrEqual(row.frame.height, 44, "place-row-\(raw) is at least 44 pt tall")
        }
    }

    func testTappingAPlaceTogglesItsSelectedTrait() {
        continueAfterFailure = false
        let app = launchAnky()
        openPlaces(in: app)

        let place = app.buttons["place-neck"]
        XCTAssertTrue(place.waitForExistence(timeout: 10))
        XCTAssertFalse(place.isSelected)

        place.tap()
        XCTAssertTrue(place.isSelected)

        place.tap()
        XCTAssertFalse(place.isSelected)
    }

    func testTappingTheEmptyMiddleOfARowTogglesItsSelectedTrait() {
        continueAfterFailure = false
        let app = launchAnky()
        openPlaces(in: app)

        let row = placeRow("neck", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let place = app.buttons["place-neck"]
        XCTAssertTrue(place.waitForExistence(timeout: 10))
        XCTAssertFalse(place.isSelected)

        // The row's accessibility frame hugs its text, so the middle of the whole row is found from the screen.
        let middleOfRow = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: row.frame.midY / app.frame.height))
        middleOfRow.tap()
        XCTAssertTrue(place.isSelected)
    }

    private func openPlaces(in app: XCUIApplication) {
        openNewEntry(app)
        let moreButton = app.buttons["more-places"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 10))
        moreButton.tap()
        XCTAssertTrue(placeRow("neck", in: app).waitForExistence(timeout: 10))
    }

    private func placeRow(_ raw: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["place-row-\(raw)"]
    }
}
