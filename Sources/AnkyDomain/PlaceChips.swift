public enum PlaceChips {
    private static let chipCount = 5
    private static let recentCount = 10
    private static let minimumCount = 2
    private static let catalogIndex = index(PlaceCatalog.allPlaces)

    public static func chips(from entries: [Entry], pinned: [PlaceID] = [], lastChips: [PlaceID] = []) -> [PlaceID] {
        let pins = pinnedPlaces(pinned)
        let used = rankedPlaces(recentPlaces(entries), lastChips: Set(lastChips), excluding: Set(pins))
        let taken = Set(pins + used)
        let presets = PlaceCatalog.defaultChips.filter { !taken.contains($0) }
        let chosen = Set((pins + used + presets).prefix(chipCount))
        return PlaceCatalog.allPlaces.filter(chosen.contains)
    }

    private struct Usage {
        let place: PlaceID
        let count: Int
        let wasChip: Bool
        let mostRecent: Int
        let bodyOrder: Int
    }

    private static func pinnedPlaces(_ pinned: [PlaceID]) -> [PlaceID] {
        let known = pinned.filter { catalogIndex[$0] != nil }
        let distinct = known.reduce(into: [PlaceID]()) { kept, place in
            if !kept.contains(place) {
                kept.append(place)
            }
        }
        return Array(distinct.prefix(chipCount))
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

    private static func rankedPlaces(
        _ recent: [[PlaceID]],
        lastChips: Set<PlaceID>,
        excluding chosen: Set<PlaceID>
    ) -> [PlaceID] {
        PlaceCatalog.allPlaces.enumerated()
            .filter { !chosen.contains($0.element) }
            .compactMap { bodyOrder, place in
                usage(of: place, in: recent, wasChip: lastChips.contains(place), bodyOrder: bodyOrder)
            }
            .sorted(by: isMoreUsed)
            .prefix(chipCount - chosen.count)
            .map(\.place)
    }

    private static func usage(of place: PlaceID, in recent: [[PlaceID]], wasChip: Bool, bodyOrder: Int) -> Usage? {
        let uses = recent.indices.filter { recent[$0].contains(place) }
        guard uses.count >= minimumCount, let mostRecent = uses.first else { return nil }
        return Usage(place: place, count: uses.count, wasChip: wasChip, mostRecent: mostRecent, bodyOrder: bodyOrder)
    }

    private static func isMoreUsed(_ lhs: Usage, _ rhs: Usage) -> Bool {
        if lhs.count != rhs.count {
            return lhs.count > rhs.count
        }
        if lhs.wasChip != rhs.wasChip {
            return lhs.wasChip
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
