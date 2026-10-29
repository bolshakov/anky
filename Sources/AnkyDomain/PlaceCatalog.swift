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
