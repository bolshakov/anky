// SPDX-License-Identifier: GPL-3.0-or-later
public struct MorePlacesValue: Equatable, Sendable {
    private static let nameCount = 2

    public let all: [PlaceID]

    public init(selected: [PlaceID], chips: [PlaceID]) {
        let picked = Set(selected)
        let shown = Set(chips)
        all = PlaceCatalog.allPlaces.filter { picked.contains($0) && !shown.contains($0) }
    }

    public var names: [PlaceID] {
        Array(all.prefix(Self.nameCount))
    }

    public var more: Int {
        all.count - names.count
    }
}
