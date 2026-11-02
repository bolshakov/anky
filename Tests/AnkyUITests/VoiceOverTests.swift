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
    }

    /// A Form keeps views that are hidden from VoiceOver in the XCUI tree, so they are checked for not being hittable.
    /// Each one must exist first, since a missing element is not hittable either.
    func testSeverityValueAndEndLabelsAreNotVoiceOverStops() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        XCTAssertTrue(app.sliders["severity-slider"].waitForExistence(timeout: 10))

        let hidden = ["How strong", "severity-value", "severity-low-label", "severity-high-label"]
        for name in hidden {
            let element = app.staticTexts[name]
            XCTAssertTrue(element.exists, "\(name) is missing, so the check cannot prove it is hidden")
            XCTAssertFalse(element.isHittable, "\(name) would be a VoiceOver stop of its own")
        }
    }
}
