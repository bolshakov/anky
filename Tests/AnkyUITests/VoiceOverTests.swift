// SPDX-License-Identifier: GPL-3.0-or-later
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
        XCTAssertEqual(slider.label, "Severity")
        XCTAssertEqual(severityLevel(of: slider), 4)
        XCTAssertEqual(app.sliders.matching(NSPredicate(format: "identifier BEGINSWITH 'severity'")).count, 1)
        // The XCUI tree of a Form row lists hidden views, so absence of their identifiers cannot be asserted there.
    }
}
