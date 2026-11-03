// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class PlaceChipSpacingTests: XCTestCase {
    func testPlaceChipsAreAboutThirtyTwoPointsTall() {
        continueAfterFailure = false
        let frames = placeChipFrames()

        XCTAssertFalse(frames.isEmpty, "the Where card shows place chips")
        for frame in frames {
            XCTAssertTrue((28.0 ... 36.0).contains(frame.height), "a place chip is \(frame.height) pt tall")
        }
    }

    func testTheGapBetweenTheFirstAndSecondRowsIsAboutEightPoints() {
        continueAfterFailure = false
        let frames = placeChipFrames()
        let firstTop = frames.map(\.minY).min() ?? 0
        let firstRow = frames.filter { $0.minY < firstTop + 1 }
        let secondRow = frames.filter { $0.minY >= firstTop + 1 }

        XCTAssertFalse(secondRow.isEmpty, "the place chips sit on two rows")
        let firstRowBottom = firstRow.map(\.maxY).max() ?? firstTop
        let secondRowTop = secondRow.map(\.minY).min() ?? firstRowBottom
        let gap = secondRowTop - firstRowBottom
        XCTAssertTrue((7.0 ... 9.0).contains(gap), "the rows are \(gap) pt apart")
    }

    /// No entry and no pin, so the Where chips are the spine and sacroiliac ones, with no recent-chips row above them.
    private func placeChipFrames() -> [CGRect] {
        let app = launchAnky()
        openNewEntry(app)
        let chips = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'place-chip-'"))
        XCTAssertTrue(chips.firstMatch.waitForExistence(timeout: 10))
        return chips.allElementsBoundByIndex.map(\.frame)
    }
}
