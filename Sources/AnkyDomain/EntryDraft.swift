import Foundation

public struct EntryDraft: Equatable, Sendable {
    public var kind: EntryKind
    public var severity: Severity
    public var date: Date
    public var note: String

    public init(severity: Severity, date: Date) {
        kind = .pain
        self.severity = severity
        self.date = date
        note = ""
    }
}
