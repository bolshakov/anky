public enum PlaceChips {
    private static let chipCount = 5
    private static let catalogIndex = index(PlaceCatalog.allPlaces)
    private static let defaultIndex = index(PlaceCatalog.defaultChips)

    public static func ranked(from entries: [Entry]) -> [PlaceID] {
        let counts = loggedCounts(entries)
        let logged = counts.keys.sorted { lhs, rhs in
            let (lhsCount, rhsCount) = (counts[lhs, default: 0], counts[rhs, default: 0])
            if lhsCount != rhsCount {
                return lhsCount > rhsCount
            }
            return tieOrder(lhs) < tieOrder(rhs)
        }
        let unlogged = PlaceCatalog.defaultChips.filter { !logged.contains($0) }
        return Array((logged + unlogged).prefix(chipCount))
    }

    public static func shown(ranked: [PlaceID], selected: [PlaceID]) -> [PlaceID] {
        let chosen = Set(selected)
        let inRanked = Set(ranked)
        return ranked + PlaceCatalog.allPlaces.filter { chosen.contains($0) && !inRanked.contains($0) }
    }

    private static func loggedCounts(_ entries: [Entry]) -> [PlaceID: Int] {
        var counts: [PlaceID: Int] = [:]
        for entry in entries {
            for place in Set(entry.places) where catalogIndex[place] != nil {
                counts[place, default: 0] += 1
            }
        }
        return counts
    }

    private static func tieOrder(_ place: PlaceID) -> (Int, Int) {
        (defaultIndex[place] ?? .max, catalogIndex[place] ?? .max)
    }

    private static func index(_ places: [PlaceID]) -> [PlaceID: Int] {
        Dictionary(uniqueKeysWithValues: places.enumerated().map { ($1, $0) })
    }
}
