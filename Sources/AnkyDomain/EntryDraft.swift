import Foundation

public struct EntryDraft: Equatable, Sendable {
    public static let noteLimit = 240

    public var kind: EntryKind
    public var severity: Severity
    public var date: Date
    public var note: String {
        didSet {
            if note.count > Self.noteLimit {
                note = String(note.prefix(Self.noteLimit))
            }
        }
    }

    public init(severity: Severity, date: Date) {
        kind = .pain
        self.severity = severity
        self.date = date
        note = ""
    }
}
