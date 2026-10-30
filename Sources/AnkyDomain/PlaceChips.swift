public enum PlaceChips {
    private static let chipCount = 5
    private static let recentCount = 10
    private static let minimumCount = 2
    private static let catalogIndex = index(PlaceCatalog.allPlaces)

    public static func chips(from entries: [Entry]) -> [PlaceID] {
        let kept = rankedPlaces(recentPlaces(entries))
        let presets = PlaceCatalog.defaultChips.filter { !kept.contains($0) }
        let chosen = Set((kept + presets).prefix(chipCount))
        return PlaceCatalog.allPlaces.filter(chosen.contains)
    }

    private struct Usage {
        let place: PlaceID
        let count: Int
        let mostRecent: Int
        let bodyOrder: Int
    }

    private static func recentPlaces(_ entries: [Entry]) -> [[PlaceID]] {
        let newestFirst = entries.enumerated()
            .sorted { ($0.element.date, $0.offset) > ($1.element.date, $1.offset) }
            .map(\.element)
        return Array(newestFirst.map(knownPlaces).filter { !$0.isEmpty }.prefix(recentCount))
    }

    private static func knownPlaces(_ entry: Entry) -> [PlaceID] {
        entry.places.filter { catalogIndex[$0] != nil }
    }

    private static func rankedPlaces(_ recent: [[PlaceID]]) -> [PlaceID] {
        PlaceCatalog.allPlaces.enumerated()
            .compactMap { bodyOrder, place in usage(of: place, in: recent, bodyOrder: bodyOrder) }
            .sorted(by: isMoreUsed)
            .prefix(chipCount)
            .map(\.place)
    }

    private static func usage(of place: PlaceID, in recent: [[PlaceID]], bodyOrder: Int) -> Usage? {
        let uses = recent.indices.filter { recent[$0].contains(place) }
        guard uses.count >= minimumCount, let mostRecent = uses.first else { return nil }
        return Usage(place: place, count: uses.count, mostRecent: mostRecent, bodyOrder: bodyOrder)
    }

    private static func isMoreUsed(_ lhs: Usage, _ rhs: Usage) -> Bool {
        if lhs.count != rhs.count {
            return lhs.count > rhs.count
        }
        if lhs.mostRecent != rhs.mostRecent {
            return lhs.mostRecent < rhs.mostRecent
        }
        return lhs.bodyOrder < rhs.bodyOrder
    }

    private static func index(_ places: [PlaceID]) -> [PlaceID: Int] {
        Dictionary(uniqueKeysWithValues: places.enumerated().map { ($1, $0) })
    }
}
