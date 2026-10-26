import Foundation

public struct Entry: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let kind: EntryKind
    public let severity: Severity
    public let date: Date
    public let note: String?

    public init(id: UUID = UUID(), draft: EntryDraft) {
        self.id = id
        kind = draft.kind
        severity = draft.severity
        date = draft.date
        let isBlank = draft.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        note = isBlank ? nil : draft.note
    }
}
