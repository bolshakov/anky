import XCTest

@MainActor
func chooseKind(_ title: String, in app: XCUIApplication) {
    let picker = app.descendants(matching: .any).matching(identifier: "kind-picker").firstMatch
    XCTAssertTrue(picker.waitForExistence(timeout: 10))
    picker.buttons[title].tap()
}
