import XCTest

@MainActor
final class KindAtLargestSizeTests: XCTestCase {
    func testKindOptionsAreTappableAndSaveAtLargestSize() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        openNewEntry(app)

        let picker = app.descendants(matching: .any).matching(identifier: "kind-picker").firstMatch
        let stiffness = picker.buttons["Stiffness"]
        XCTAssertTrue(stiffness.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(stiffness.frame.height, 44)

        chooseKind("Stiffness", in: app)
        scrollToSeveritySlider(in: app)
        setSeverity(4, in: app)
        saveEntry(app)

        let row = app.descendants(matching: .any).matching(identifier: "entry-row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(row.label.hasSuffix(", Stiffness, 4 of 10"), "row reads \(row.label)")
    }
}
