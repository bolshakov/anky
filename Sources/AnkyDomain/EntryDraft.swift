import Foundation

public struct EntryDraft: Equatable, Sendable {
    public static let noteLimit = 240

    public var kind: EntryKind
    public var severity: Severity
    public var date: Date
    public var places: [PlaceID] = [] {
        didSet {
            places = PlaceCatalog.canonicalOrder(places)
        }
    }

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
        places = entry.places
        // Observers do not run for an assignment made in an initializer, so the note limit is applied here.
        note = String((entry.note ?? "").prefix(Self.noteLimit))
    }

    public var placeCount: Int {
        places.filter { PlaceCatalog.joint(of: $0) != nil }.count
    }

    public mutating func togglePlace(_ id: PlaceID) {
        if places.contains(id) {
            places.removeAll { $0 == id }
        } else {
            places.append(id)
        }
    }
}
