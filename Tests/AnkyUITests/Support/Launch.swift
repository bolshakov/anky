import XCTest

@MainActor
func launchAnky(arguments: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-AppleLocale", "en_GB"] + arguments
    app.launch()
    XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    return app
}

extension XCTestCase {
    @MainActor
    func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
