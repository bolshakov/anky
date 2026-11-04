// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class CheckInBannerTests: XCTestCase {
    /// The title shows the medication's name as typed: a percent sign, braces and a format specifier stay in it.
    func testBannerTitleReadsTheNameAsTyped() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        addZorblexCheckingInAfterThirtyMinutes(app, medication: "Zorblex 100% {x} %@")
        saveDoseAnHourBack(in: app)
        openCheckIn(app)

        XCTAssertTrue(identified("check-in-info", in: app).label.hasPrefix("Zorblex 100% {x} %@. Taken at "))
    }
}
