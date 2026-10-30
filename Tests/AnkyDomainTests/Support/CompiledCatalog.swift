import Foundation
import Testing

/// The app's string catalog, read two ways: compiled into one bundle per language, the way the app ships it, and as
/// the JSON file itself, for what a bundle does not show.
enum CompiledCatalog {
    static let fileURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "App/Localizable.xcstrings")

    /// Compiles the catalog into a new folder, hands the `<language>.lproj` bundle to `body`, and removes the folder
    /// when `body` returns. Each call has its own folder, so tests that run in parallel share no state.
    static func withBundle<T>(_ language: String, _ body: (Bundle) throws -> T) throws -> T {
        let output = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: output) }
        try compile(into: output)
        let bundle = try #require(Bundle(path: output.appending(path: "\(language).lproj").path))
        return try body(bundle)
    }

    static func entries() throws -> [String: Entry] {
        try JSONDecoder().decode(File.self, from: Data(contentsOf: fileURL)).strings
    }

    private static func compile(into output: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["xcstringstool", "compile", fileURL.path, "--output-directory", output.path]
        try process.run()
        process.waitUntilExit()
        try #require(process.terminationStatus == 0)
    }
}

extension CompiledCatalog {
    struct File: Decodable {
        let strings: [String: Entry]
    }

    struct Entry: Decodable {
        let localizations: [String: Localization]?
    }

    struct Localization: Decodable {
        let stringUnit: StringUnit?
        let variations: Variations?

        var stringUnits: [StringUnit] {
            stringUnit.map { [$0] } ?? variations?.plural.values.compactMap(\.stringUnit) ?? []
        }
    }

    struct StringUnit: Decodable {
        let state: String
        let value: String
    }

    struct Variations: Decodable {
        let plural: [String: Localization]
    }
}
