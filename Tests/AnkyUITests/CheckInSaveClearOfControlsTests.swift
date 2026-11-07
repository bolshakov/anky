// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// Save check-in is pinned to the bottom, so at the end of the form the note sits above it.
@MainActor
final class CheckInSaveClearOfControlsTests: XCTestCase {
    func testNoteAndSliderEndAboveSaveAtTheDefaultSize() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        setUpWaitingPainDose(in: app)
        openCheckIn(app)

        setSeverity(6, in: app)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 6)
        XCTAssertTrue(identified("check-in-screen", in: app).exists)

        scrollToBottom(of: app)
        assertAboveSave(["severity-slider", "note-field"], in: app)
    }

    func testNoteEndsAboveSaveAtTheLargestSize() throws {
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
        assertAboveSave(["note-field"], in: app)
        swipeBackToSlider(in: app)
        setSeverity(6, in: app)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 6)
        XCTAssertTrue(identified("check-in-screen", in: app).exists)
    }

    /// The walk above ends at the bottom of the form, with the slider scrolled off the top, so it is swiped back.
    private func swipeBackToSlider(in app: XCUIApplication) {
        let slider = app.sliders["severity-slider"]
        let screen = identified("check-in-screen", in: app)
        for _ in 0 ..< 8 where !slider.isHittable {
            screen.swipeDown()
        }
    }

    private func assertAboveSave(
        _ ids: [String],
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let save = app.buttons["save-check-in"]
        XCTAssertTrue(save.exists, "save-check-in is not on screen at the end of the form", file: file, line: line)
        for id in ids {
            let control = identified(id, in: app)
            XCTAssertTrue(control.exists, "\(id) is not on screen", file: file, line: line)
            XCTAssertLessThanOrEqual(control.frame.maxY, save.frame.minY, file: file, line: line)
        }
    }

    private func setUpWaitingPainDose(in app: XCUIApplication) {
        saveEntryAnHourBack(.pain, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
    }
}
