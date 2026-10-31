// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum RecentName: Equatable, Hashable, Sendable {
    case place(PlaceID)
    case pair(Joint)
}

public struct RecentEntry: Equatable, Hashable, Sendable {
    public let kind: EntryKind
    public let severity: Severity
    public let places: [PlaceID]
    public let names: [RecentName]

    private static let shownCount = 2

    public var shownNames: [RecentName] {
        Array(names.prefix(Self.shownCount))
    }

    public var hiddenCount: Int {
        names.count - shownNames.count
    }

    public var showsKind: Bool {
        kind != .pain
    }

    public var showsNoPlace: Bool {
        kind.asksWhere && names.isEmpty
    }

    public init(_ entry: Entry) {
        kind = entry.kind
        severity = entry.severity
        places = Self.knownPlaces(of: entry)
        names = Self.names(of: places)
    }

    public func draft(at date: Date) -> EntryDraft {
        var draft = EntryDraft(severity: severity, date: date)
        draft.kind = kind
        draft.places = places
        return draft
    }

    private static func knownPlaces(of entry: Entry) -> [PlaceID] {
        guard entry.kind.asksWhere else { return [] }
        let chosen = Set(entry.places)
        return PlaceCatalog.allPlaces.filter(chosen.contains)
    }

    private static func names(of places: [PlaceID]) -> [RecentName] {
        let chosen = Set(places)
        return places.compactMap { place -> RecentName? in
            guard let joint = PlaceCatalog.joint(of: place), joint.isPaired,
                  joint.places.allSatisfy(chosen.contains) else { return .place(place) }
            return place == joint.places.first ? .pair(joint) : nil
        }
    }
}
