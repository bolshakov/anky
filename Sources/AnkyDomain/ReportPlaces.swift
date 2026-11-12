// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct ReportPlaceCount: Equatable, Sendable {
    public let place: PlaceID
    public let name: String
    public let count: Int

    public init(place: PlaceID, name: String, count: Int) {
        self.place = place
        self.name = name
        self.count = count
    }
}

/// The places logged from the period's start to `now`, both ends included, the most logged first. An entry adds one
/// to every place it carries. A place `name` gives no name for is one this build does not know, so it is left out.
public struct ReportPlaces: Equatable, Sendable {
    private static let shownLimit = 6

    public let shown: [ReportPlaceCount]
    public let moreCount: Int

    public init(
        entries: [Entry], period: ReportPeriod, now: Date, calendar: Calendar, locale: Locale, name: (PlaceID) -> String
    ) {
        // #lizard forgives
        let range = period.start(endingAt: now, calendar: calendar) ... now
        let places = entries.filter { range.contains($0.date) }.flatMap { Set($0.places) }
        let counts = Dictionary(places.map { ($0, 1) }, uniquingKeysWith: +)
        let ranked = counts
            .map { ReportPlaceCount(place: $0.key, name: name($0.key), count: $0.value) }
            .filter { !$0.name.isEmpty }
            .sorted { Self.readsFirst($0, $1, locale: locale) }
        shown = Array(ranked.prefix(Self.shownLimit))
        moreCount = ranked.count - shown.count
    }

    /// Equal names fall back to the id, so the order is the same on every build.
    private static func readsFirst(_ lhs: ReportPlaceCount, _ rhs: ReportPlaceCount, locale: Locale) -> Bool {
        if lhs.count != rhs.count {
            return lhs.count > rhs.count
        }
        switch lhs.name.compare(rhs.name, options: standardComparison, locale: locale) {
        case .orderedAscending: return true
        case .orderedDescending: return false
        case .orderedSame: return lhs.place.rawValue < rhs.place.rawValue
        }
    }

    private static let standardComparison: String.CompareOptions = [.caseInsensitive, .numeric, .widthInsensitive]
}
