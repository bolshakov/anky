public enum PinOutcome: Equatable, Sendable {
    case pinned
    case alreadyPinned
    case refused
}

public struct Shortcuts: Equatable, Sendable {
    public static let pinLimit = 5

    public private(set) var pinned: [PlaceID]
    public private(set) var lastChips: [PlaceID]

    public init(pinned: [PlaceID] = [], lastChips: [PlaceID] = []) {
        self.pinned = pinned
        self.lastChips = lastChips
    }

    @discardableResult
    public mutating func pin(_ place: PlaceID) -> PinOutcome {
        pin(all: [place])
    }

    @discardableResult
    public mutating func pin(all places: [PlaceID]) -> PinOutcome {
        var seen = Set(pinned)
        let fresh = places.filter { seen.insert($0).inserted }
        guard !fresh.isEmpty else { return .alreadyPinned }
        guard pinned.count + fresh.count <= Self.pinLimit else { return .refused }
        pinned += fresh
        return .pinned
    }

    public mutating func unpin(_ place: PlaceID) {
        pinned.removeAll { $0 == place }
    }

    public mutating func setLastChips(_ chips: [PlaceID]) {
        lastChips = chips
    }
}
