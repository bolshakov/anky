import XCTest

@MainActor
final class VoiceOverTests: XCTestCase {
    /// XCUITest has no accessibility increment or decrement, so the one-step swipe is system Slider behaviour that only
    /// a hand with VoiceOver on can check.
    func testSeverityReadsAndSteps() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(4, in: app)

        let slider = app.sliders["severity-slider"]
        XCTAssertFalse(slider.label.isEmpty)
        XCTAssertEqual(severityLevel(of: slider), 4)
    }
}
