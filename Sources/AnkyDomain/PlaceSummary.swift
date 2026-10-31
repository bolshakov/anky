// SPDX-License-Identifier: GPL-3.0-or-later
public enum PlaceSummary: Equatable, Sendable {
    case wholeBody
    case noPlace
    case places([PlaceID])
}

public extension Entry {
    var placeSummary: PlaceSummary {
        guard kind.asksWhere else { return .wholeBody }
        let known = PlaceCatalog.allPlaces.filter { places.contains($0) }
        return known.isEmpty ? .noPlace : .places(known)
    }
}
