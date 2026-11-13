// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct RemovedCheckInRowTests {
    private static let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private static let removedTexts = ["\"check-in-after\"", "Check in after a dose"]

    @Test func appHoldsNeitherTheRemovedCheckInRowIdNorItsHeading() throws {
        let appFolder = Self.repositoryRoot.appending(path: "App", directoryHint: .isDirectory)
        let files = try Self.sourceFiles(under: appFolder)
        #expect(files.contains { $0.pathExtension == "swift" }, "No Swift file under \(appFolder.path)")

        let found = try files.flatMap { file in
            let text = try String(contentsOf: file, encoding: .utf8)
            return Self.removedTexts.filter(text.contains).map { "\(file.path) holds \($0)" }
        }
        #expect(found.isEmpty, "The removed check-in row is back: \(found.joined(separator: ", "))")
    }

    private static func sourceFiles(under appFolder: URL) throws -> [URL] {
        let enumerator = try #require(
            FileManager.default.enumerator(at: appFolder, includingPropertiesForKeys: nil),
            "Cannot read \(appFolder.path)"
        )
        return enumerator.compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" || $0.lastPathComponent == "Localizable.xcstrings" }
    }
}
