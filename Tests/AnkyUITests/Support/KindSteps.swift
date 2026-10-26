import XCTest

@MainActor
func chooseKind(_ title: String, in app: XCUIApplication) {
    let picker = app.segmentedControls["kind-picker"]
    XCTAssertTrue(picker.waitForExistence(timeout: 10))
    picker.buttons[title].tap()
}
