// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

enum Presentation {
    case english, doubleLength, rightToLeft
    case region(language: String, region: String)

    var launchArguments: [String] {
        switch self {
        case .english:
            ["-AppleLocale", "en_GB"]
        case .doubleLength:
            ["-AppleLocale", "en_GB", "-NSDoubleLocalizedStrings", "YES"]
        case .rightToLeft:
            ["-AppleLocale", "en_GB", "-NSForceRightToLeftWritingDirection", "YES", "-AppleTextDirection", "YES"]
        case let .region(language, region):
            ["-AppleLanguages", "(\(language))", "-AppleLocale", "\(language)_\(region)"]
        }
    }
}

/// The run's look replaces only the default `.english`, so a test that names its look keeps it.
private func lookForRun(_ presentation: Presentation) -> Presentation {
    guard case .english = presentation else { return presentation }
    switch ProcessInfo.processInfo.environment["ANKY_PRESENTATION"] {
    case "doubleLength": return .doubleLength
    case "rightToLeft": return .rightToLeft
    default: return .english
    }
}

@MainActor
func launchAnky(
    folder: String = UUID().uuidString,
    presentation: Presentation = .english,
    arguments: [String] = []
) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = lookForRun(presentation).launchArguments + arguments
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
