// SPDX-License-Identifier: GPL-3.0-or-later
public enum PlaceCatalog {
    public static var allPlaces: [PlaceID] {
        Joint.allCases.flatMap(\.places)
    }

    public static var defaultChips: [PlaceID] {
        [Joint.lowerBack, .siJoint, .neck, .upperBack].flatMap(\.places)
    }

    public static func joints(in group: PlaceGroup) -> [Joint] {
        Joint.allCases.filter { $0.group == group }
    }

    public static func joint(of place: PlaceID) -> Joint? {
        Joint.allCases.first { $0.places.contains(place) }
    }

    public static func side(of place: PlaceID) -> Side? {
        guard let joint = joint(of: place) else { return nil }
        return [Side.left, .right].first { joint.place($0) == place }
    }
}

extension PlaceCatalog {
    /// Places this build does not know go last, in the order given, so a later build's place is kept, not dropped.
    static func canonicalOrder(_ places: [PlaceID]) -> [PlaceID] {
        let catalogIndex = Dictionary(uniqueKeysWithValues: allPlaces.enumerated().map { ($1, $0) })
        let known = places
            .filter { catalogIndex[$0] != nil }
            .sorted { catalogIndex[$0, default: 0] < catalogIndex[$1, default: 0] }
        return known + places.filter { catalogIndex[$0] == nil }
    }
}
