// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class PlaceChipSelectionTests: XCTestCase {
    /// The check mark is hidden from VoiceOver, so an unselected chip is read as its place name and nothing else.
    func testPlaceChipIsReadAsItsNameWhetherOrNotSelected() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let neck = app.buttons["place-chip-neck"]
        XCTAssertTrue(neck.waitForExistence(timeout: 10))
        XCTAssertFalse(neck.isSelected)
        XCTAssertEqual(neck.label, "Neck")

        neck.tap()
        XCTAssertTrue(waitUntilSelected(neck, true))
        XCTAssertEqual(neck.label, "Neck")
    }

    private func waitUntilSelected(_ chip: XCUIElement, _ selected: Bool) -> Bool {
        let predicate = NSPredicate(format: "selected == %@", NSNumber(value: selected))
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: chip)
        return XCTWaiter().wait(for: [expectation], timeout: 5) == .completed
    }
}
