// SPDX-License-Identifier: GPL-3.0-or-later
public struct TipProgress: Equatable, Sendable {
    public static let visitsNeeded = 3
    public static let picksNeeded = 3

    public private(set) var visits: Int
    public private(set) var picks: [String: Int]

    public var isReady: Bool {
        visits >= Self.visitsNeeded || picks.values.contains { $0 >= Self.picksNeeded }
    }

    public init(visits: Int = 0, picks: [String: Int] = [:]) {
        self.visits = visits
        self.picks = picks
    }

    public mutating func recordVisit() {
        visits += 1
    }

    public mutating func recordPick(_ place: PlaceID) {
        picks[place.rawValue, default: 0] += 1
    }
}
