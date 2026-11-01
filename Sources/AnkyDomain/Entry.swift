// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct Entry: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let kind: EntryKind
    public let severity: Severity
    public let date: Date
    public let note: String?
    public let places: [PlaceID]

    public init(id: UUID = UUID(), draft: EntryDraft) {
        self.id = id
        kind = draft.kind
        severity = draft.severity
        date = draft.date
        let isBlank = draft.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        note = isBlank ? nil : draft.note
        places = Self.keptPlaces(draft.places, for: draft.kind)
    }

    public init(id: UUID, kind: EntryKind, severity: Severity, date: Date, note: String?, places: [PlaceID]) {
        // #lizard forgives
        self.id = id
        self.kind = kind
        self.severity = severity
        self.date = date
        self.note = note
        self.places = Self.keptPlaces(places, for: kind)
    }

    public init(from decoder: any Decoder) throws {
        let stored = try StoredEntry(from: decoder)
        id = stored.id
        kind = stored.kind
        severity = stored.severity
        date = stored.date
        note = stored.note
        places = Self.keptPlaces(stored.places ?? [], for: stored.kind)
    }

    private struct StoredEntry: Decodable {
        let id: UUID
        let kind: EntryKind
        let severity: Severity
        let date: Date
        let note: String?
        let places: [PlaceID]?
    }

    private static func keptPlaces(_ places: [PlaceID], for kind: EntryKind) -> [PlaceID] {
        kind.asksWhere ? PlaceCatalog.canonicalOrder(places) : []
    }
}
