// SPDX-License-Identifier: GPL-3.0-or-later
import Vision
import XCTest

@MainActor
final class EntryRowLargestTextTests: XCTestCase {
    /// The row's words are hidden from the accessibility tree, so the check reads the pixels of the row. A word split
    /// across lines reads as a fragment, so the whole words must each be read as one token.
    func testRowHoldsWholeWordsAtLargestSize() throws {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let english = Presentation.region(language: "en", region: "GB")

        let app = launchAnky(folder: folder, presentation: english)
        openNewEntry(app)
        chooseKind(.stiffness, in: app)
        let lowerBack = app.buttons["place-chip-lower"]
        XCTAssertTrue(lowerBack.waitForExistence(timeout: 10))
        lowerBack.tap()
        setSeverity(4, in: app)
        saveEntry(app)
        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
        app.terminate()

        let relaunched = launchAnky(folder: folder, presentation: english, arguments: largestTextArguments)
        let row = relaunched.descendants(matching: .any).matching(identifier: "entry-row-stiffness").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let floatingTop = min(
            relaunched.buttons["log-medication"].frame.minY,
            relaunched.buttons["log-entry"].frame.minY
        )
        // The floating buttons cover the middle of the screen at this size, so each drag starts above them and moves
        // the row by the distance it still lacks, which stops it just clear of the buttons and not under the title.
        let origin = relaunched.coordinate(withNormalizedOffset: .zero)
        let start = origin.withOffset(CGVector(dx: relaunched.frame.midX, dy: 300))
        for _ in 0 ..< 6 where row.frame.maxY > floatingTop {
            let distance = min(row.frame.maxY - floatingTop + 4, 250)
            start.press(
                forDuration: 0.1,
                thenDragTo: origin.withOffset(CGVector(dx: relaunched.frame.midX, dy: 300 - distance))
            )
        }
        XCTAssertLessThanOrEqual(row.frame.maxY, floatingTop)
        attachScreenshot(named: "entry-row-largest-text")

        let words = try recognizedWords(in: rowImage(of: row, in: relaunched))
        for word in ["Stiffness", "Lower", "back", "4"] {
            XCTAssertTrue(words.contains(word), "\(word) is not read whole in \(words)")
        }
        XCTAssertFalse(words.contains("of"), "the row shows the number alone in \(words)")
        XCTAssertFalse(words.contains { $0.hasSuffix("-") }, "a word is split across lines in \(words)")
    }

    /// The row's own element screenshot is not cropped to the row here, so the row is cut from the app's screenshot.
    private func rowImage(of row: XCUIElement, in app: XCUIApplication) throws -> CGImage {
        let screen = try XCTUnwrap(app.screenshot().image.cgImage)
        let scale = CGFloat(screen.width) / app.frame.width
        let rect = CGRect(
            x: row.frame.minX * scale,
            y: row.frame.minY * scale,
            width: row.frame.width * scale,
            height: row.frame.height * scale
        )
        return try XCTUnwrap(screen.cropping(to: rect))
    }

    private func recognizedWords(in image: CGImage) throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: image).perform([request])
        let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        return lines.flatMap { $0.split(whereSeparator: \.isWhitespace).map(String.init) }
    }
}
