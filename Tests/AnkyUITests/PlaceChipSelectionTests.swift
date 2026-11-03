// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class PlaceChipSelectionTests: XCTestCase {
    private let extraExtraLargeText = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXL"]

    /// Selecting a chip adds its check mark, and the chip must keep its frame so that no chip moves to another row.
    func testSelectingOrDeselectingAPlaceChipMovesNoChip() {
        continueAfterFailure = false
        let app = launchAnky(arguments: extraExtraLargeText)
        openNewEntry(app)

        let baseline = placeChipFrames(in: app)
        XCTAssertFalse(baseline.isEmpty, "the Where card shows place chips")

        for identifier in baseline.keys.sorted() {
            let chip = app.buttons[identifier]
            chip.tap()
            XCTAssertTrue(waitUntilSelected(chip, true), "\(identifier) is not selected after a tap")
            assertFrames(placeChipFrames(in: app), match: baseline, after: "selecting \(identifier)")

            chip.tap()
            XCTAssertTrue(waitUntilSelected(chip, false), "\(identifier) is still selected after a second tap")
            assertFrames(placeChipFrames(in: app), match: baseline, after: "deselecting \(identifier)")
        }
    }

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

    /// Frames keyed by identifier, read from the chips on screen.
    private func placeChipFrames(in app: XCUIApplication) -> [String: CGRect] {
        let chips = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'place-chip-'"))
        XCTAssertTrue(chips.firstMatch.waitForExistence(timeout: 10))
        var frames: [String: CGRect] = [:]
        for chip in chips.allElementsBoundByIndex {
            frames[chip.identifier] = chip.frame
        }
        return frames
    }

    private func assertFrames(_ frames: [String: CGRect], match baseline: [String: CGRect], after step: String) {
        XCTAssertEqual(Set(frames.keys), Set(baseline.keys), "the chips shown changed after \(step)")
        for (identifier, expected) in baseline {
            guard let actual = frames[identifier] else { continue }
            XCTAssertEqual(actual.minX, expected.minX, accuracy: 0.5, "\(identifier) moved x after \(step)")
            XCTAssertEqual(actual.minY, expected.minY, accuracy: 0.5, "\(identifier) moved y after \(step)")
            XCTAssertEqual(actual.width, expected.width, accuracy: 0.5, "\(identifier) changed width after \(step)")
            XCTAssertEqual(actual.height, expected.height, accuracy: 0.5, "\(identifier) changed height after \(step)")
        }
    }

    private func waitUntilSelected(_ chip: XCUIElement, _ selected: Bool) -> Bool {
        let predicate = NSPredicate(format: "selected == %@", NSNumber(value: selected))
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: chip)
        return XCTWaiter().wait(for: [expectation], timeout: 5) == .completed
    }
}
