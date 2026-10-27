import XCTest

@MainActor
final class SeverityDragTests: XCTestCase {
    func testDragSetsTheLevelWhereTheFingerLands() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let slider = app.sliders["severity-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        drag(slider, toNormalizedPosition: 0.8)
        XCTAssertEqual(slider.value as? String, "8 of 10")
        drag(slider, toNormalizedPosition: 0.3)
        XCTAssertEqual(slider.value as? String, "3 of 10")
    }

    func testDragPastTheEndStopsAtTen() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let slider = app.sliders["severity-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        drag(slider, toNormalizedPosition: 1.2)
        XCTAssertEqual(slider.value as? String, "10 of 10")
    }

    private func drag(_ slider: XCUIElement, toNormalizedPosition position: CGFloat) {
        let start = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = slider.coordinate(withNormalizedOffset: CGVector(dx: position, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
