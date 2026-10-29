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

    public init(entry: Entry) {
        self.init(severity: entry.severity, date: entry.date)
        kind = entry.kind
        // Observers do not run for an assignment made in an initializer, so the note limit is applied here.
        note = String((entry.note ?? "").prefix(Self.noteLimit))
    }
}
