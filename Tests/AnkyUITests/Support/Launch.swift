import XCTest

@MainActor
func launchAnky(folder: String = UUID().uuidString, arguments: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-AppleLocale", "en_GB"] + arguments
    app.launchEnvironment["ANKY_ENTRIES_FOLDER"] = folder
    app.launch()
    XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    return app
}

@MainActor
extension XCTestCase {
    func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
