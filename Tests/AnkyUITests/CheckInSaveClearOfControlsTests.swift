// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// Save is the ✓ in the top bar, so at the end of the form the note sits the clearance above the bottom edge.
@MainActor
final class CheckInSaveClearOfControlsTests: XCTestCase {
    func testNoteAndSliderEndAboveTheBottomEdgeAtTheDefaultSize() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        setUpWaitingPainDose(in: app)
        openCheckIn(app)

        setSeverity(6, in: app)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 6)
        XCTAssertTrue(identified("check-in-screen", in: app).exists)

        scrollToBottom(of: app)
        assertAboveBottomEdge(["severity-slider", "note-field"], in: app)
    }

    func testNoteEndsAboveTheBottomEdgeAtTheLargestSize() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let folder = UUID().uuidString
        let setUp = launchAnky(folder: folder)
        setUpWaitingPainDose(in: setUp)
        setUp.terminate()
        let app = launchAnky(folder: folder, arguments: largestTextArguments)
        openCheckIn(app)

        let screen = identified("check-in-screen", in: app)
        for _ in 0 ..< 6 {
            screen.swipeUp()
        }
        assertAboveBottomEdge(["note-field"], in: app)
        swipeBackToSlider(in: app)
        setSeverity(6, in: app)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 6)
        XCTAssertTrue(identified("check-in-screen", in: app).exists)
    }

    /// The walk above ends at the bottom of the form, with the slider scrolled off the top, so it is swiped back until
    /// it sits below the top bar, which would otherwise take the press that moves the knob.
    private func swipeBackToSlider(in app: XCUIApplication) {
        let slider = app.sliders["severity-slider"]
        let screen = identified("check-in-screen", in: app)
        for _ in 0 ..< 8 where !slider.isHittable || slider.frame.minY < topBarBottom {
            screen.swipeDown()
        }
    }

    private let bottomClearance: CGFloat = 16
    private let topBarBottom: CGFloat = 120

    private func assertAboveBottomEdge(
        _ ids: [String],
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let limit = app.windows.firstMatch.frame.maxY - bottomClearance
        for id in ids {
            let control = identified(id, in: app)
            XCTAssertTrue(control.exists, "\(id) is not on screen", file: file, line: line)
            XCTAssertLessThanOrEqual(control.frame.maxY, limit, file: file, line: line)
        }
    }

    private func setUpWaitingPainDose(in app: XCUIApplication) {
        saveEntryAnHourBack(.pain, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
    }
}
