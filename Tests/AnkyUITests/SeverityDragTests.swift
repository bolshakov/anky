// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class SeverityDragTests: XCTestCase {
    func testDragOfTheKnobMovesTheLevelWithTheFinger() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let slider = app.sliders["severity-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))

        drag(slider, toLevel: 8)
        assertLevel(slider, isNear: 8)
        drag(slider, toLevel: 3)
        assertLevel(slider, isNear: 3)
    }

    func testAFastFlickToEitherEndLandsOnThatEnd() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let slider = app.sliders["severity-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))

        flick(slider, fromLevel: 0, towardEnd: 1)
        XCTAssertEqual(severityLevel(of: slider), 10)
        flick(slider, fromLevel: 10, towardEnd: 0)
        XCTAssertEqual(severityLevel(of: slider), 0)
    }

    /// Starts from the knob's current level, so the second drag grabs the knob wherever the first one left it.
    private func drag(_ slider: XCUIElement, toLevel: Int) {
        let start = knobCoordinate(of: slider, level: severityLevel(of: slider) ?? 0)
        start.press(forDuration: 0.5, thenDragTo: knobCoordinate(of: slider, level: toLevel))
    }

    /// A press-and-drag can settle one level short of the finger, so the test allows one level either way.
    private func assertLevel(
        _ slider: XCUIElement,
        isNear level: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let value = severityLevel(of: slider) ?? -1
        XCTAssertLessThanOrEqual(
            abs(value - level), 1, "the level is \(value), not within one of \(level)", file: file, line: line
        )
    }

    /// Flicks the knob past the track end in the given direction, so the value must reach that end.
    private func flick(_ slider: XCUIElement, fromLevel: Int, towardEnd end: CGFloat) {
        let start = knobCoordinate(of: slider, level: fromLevel)
        let far = slider.coordinate(withNormalizedOffset: CGVector(dx: end, dy: 0.5))
        start.press(forDuration: 0.5, thenDragTo: far, withVelocity: .fast, thenHoldForDuration: 0)
    }
}
