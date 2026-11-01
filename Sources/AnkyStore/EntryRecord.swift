// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import SwiftData

/// No unique attribute, so the schema stays valid for a later sync. Every insert path must check the id first.
@Model final class EntryRecord {
    var id: UUID = UUID()
    var kind: String = ""
    var severity: Int = 0
    var date: Date = Date.distantPast
    var note: String?
    var places: [String] = []
    var position: Int = 0

    init(id: UUID, kind: String, severity: Int, date: Date, note: String?, places: [String], position: Int) {
        // #lizard forgives
        self.id = id
        self.kind = kind
        self.severity = severity
        self.date = date
        self.note = note
        self.places = places
        self.position = position
    }

    convenience init(_ entry: Entry, position: Int) {
        self.init(
            id: entry.id,
            kind: entry.kind.rawValue,
            severity: entry.severity.value,
            date: entry.date,
            note: entry.note,
            places: entry.places.map(\.rawValue),
            position: position
        )
    }

    /// Writes every field except the id and the save-order position.
    func assign(_ entry: Entry) {
        kind = entry.kind.rawValue
        severity = entry.severity.value
        date = entry.date
        note = entry.note
        places = entry.places.map(\.rawValue)
    }

    func entry() throws -> Entry {
        guard let entryKind = EntryKind(rawValue: kind), let level = Severity(severity) else {
            throw EntryStoreError.unreadable
        }
        return Entry(
            id: id,
            kind: entryKind,
            severity: level,
            date: date,
            note: note,
            places: places.map { PlaceID(rawValue: $0) }
        )
    }
}
