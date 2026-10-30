import Foundation

public protocol ShortcutsStore: Sendable {
    func load() -> Shortcuts
    func save(_ shortcuts: Shortcuts) throws
}

public struct FileShortcutsStore: ShortcutsStore {
    private static let currentVersion = 1

    private let fileURL: URL
    private let protection: FileProtection

    public init(fileURL: URL, protection: FileProtection) {
        self.fileURL = fileURL
        self.protection = protection
    }

    public func load() -> Shortcuts {
        guard let data = try? Data(contentsOf: fileURL),
              let file = try? JSONDecoder().decode(ShortcutsFile.self, from: data),
              file.version == Self.currentVersion
        else { return Shortcuts() }
        return Shortcuts(pinned: file.pinned, lastChips: file.lastChips)
    }

    public func save(_ shortcuts: Shortcuts) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let file = ShortcutsFile(
            version: Self.currentVersion,
            pinned: shortcuts.pinned,
            lastChips: shortcuts.lastChips
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(file).write(to: fileURL, options: writingOptions)
    }

    private var writingOptions: Data.WritingOptions {
        switch protection {
        case .complete: [.atomic, .completeFileProtection]
        case .deviceDefault: [.atomic]
        }
    }
}

private struct ShortcutsFile: Codable {
    let version: Int
    let pinned: [PlaceID]
    let lastChips: [PlaceID]
}
