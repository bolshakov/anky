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
            let place = app.buttons["place-\(raw)"]
            XCTAssertTrue(place.waitForExistence(timeout: 10), "place-\(raw) is on screen")
            XCTAssertGreaterThanOrEqual(place.frame.height, 44, "place-\(raw) is at least 44 pt tall")
        }
    }

    func testTappingAPlaceTogglesItsSelectedTrait() {
        continueAfterFailure = false
        let app = launchAnky()
        openPlaces(in: app)

        let place = app.buttons["place-neck"]
        XCTAssertTrue(place.waitForExistence(timeout: 10))
        XCTAssertFalse(place.isSelected)

        tapName(of: "neck", in: app)
        XCTAssertTrue(place.isSelected)

        tapName(of: "neck", in: app)
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

    /// The name's frame is the row container's frame, so it follows the text in every presentation. The tap goes by
    /// coordinate, because a plain tap on the button fails its hittability check.
    private func tapName(of raw: String, in app: XCUIApplication) {
        let place = app.buttons["place-\(raw)"]
        let name = placeRow(raw, in: app).frame
        place.coordinate(withNormalizedOffset: CGVector(
            dx: (name.midX - place.frame.minX) / place.frame.width,
            dy: (name.midY - place.frame.minY) / place.frame.height
        )).tap()
    }
}
