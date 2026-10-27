import XCTest

@MainActor
final class VoiceOverTests: XCTestCase {
    func testSeverityReadsAndSteps() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(4, in: app)

        let slider = app.sliders["severity-slider"]
        XCTAssertEqual(slider.label, "Severity")
        XCTAssertEqual(slider.value as? String, "4 of 10")

        // The SDK has no increment() or decrement(), so the test reaches each value by its position.
        setSeverity(5, in: app)
        XCTAssertEqual(slider.value as? String, "5 of 10")

        setSeverity(4, in: app)
        XCTAssertEqual(slider.value as? String, "4 of 10")
    }
}
