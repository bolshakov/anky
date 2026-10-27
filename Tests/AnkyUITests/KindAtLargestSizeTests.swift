import XCTest

@MainActor
final class KindAtLargestSizeTests: XCTestCase {
    func testKindOptionsAreTappableAndSaveAtLargestSize() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        openNewEntry(app)

        let stiffness = kindSegment(.stiffness, in: app)
        XCTAssertTrue(stiffness.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(stiffness.frame.height, 44)

        chooseKind(.stiffness, in: app)
        scrollToSeveritySlider(in: app)
        setSeverity(4, in: app)
        saveEntry(app)

        let row = app.descendants(matching: .any).matching(identifier: "entry-row-stiffness").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(rowSeverity(of: row), 4)
    }
}
