// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportPlacesTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        return calendar
    }()

    private let english = Locale(identifier: "en_GB")

    /// Wednesday 11 November 2026, 15:00. A month back starts at midnight on 11 October.
    private var now: Date {
        get throws { try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 15))) }
    }

    private var start: Date {
        get throws { try ReportPeriod.oneMonth.start(endingAt: now, calendar: calendar) }
    }

    private func entry(at date: Date, _ places: [String]) throws -> Entry {
        try Entry(
            id: UUID(),
            kind: .pain,
            severity: #require(Severity(4)),
            date: date,
            note: nil,
            places: places.map(PlaceID.init(rawValue:))
        )
    }

    private func entries(_ places: [String]...) throws -> [Entry] {
        let now = try now
        return try places.enumerated().map { index, places in
            try entry(at: now.addingTimeInterval(-Double(index + 1) * 3600), places)
        }
    }

    private func report(
        _ entries: [Entry], locale: Locale? = nil, name: (PlaceID) -> String = { $0.rawValue }
    ) throws -> ReportPlaces {
        try ReportPlaces(
            entries: entries, period: .oneMonth, now: now, calendar: calendar, locale: locale ?? english, name: name
        )
    }

    private func counts(_ places: ReportPlaces) -> [String] {
        places.shown.map { "\($0.name) \($0.count)" }
    }

    @Test func anEntryWithTwoPlacesCountsOnceForEach() throws {
        let places = try report(entries(["Neck", "Jaw"], ["Neck"]))
        #expect(counts(places) == ["Neck 2", "Jaw 1"])
    }

    @Test func aPlaceTwiceInOneEntryCountsOnce() throws {
        let places = try report(entries(["Neck", "Neck"]))
        #expect(counts(places) == ["Neck 1"])
    }

    @Test func eachCountCarriesItsPlaceAndName() throws {
        let places = try report(entries(["neck"]), name: { "Neck (\($0.rawValue))" })
        #expect(places.shown == [ReportPlaceCount(place: PlaceID(rawValue: "neck"), name: "Neck (neck)", count: 1)])
    }

    @Test func placesSortByCountThenByName() throws {
        let places = try report(entries(
            ["Upper back"], ["Right SI joint", "Lower back"], ["Left SI joint", "Lower back"],
            ["Right SI joint"], ["Left SI joint"], ["Lower back"]
        ))
        #expect(counts(places) == ["Lower back 3", "Left SI joint 2", "Right SI joint 2", "Upper back 1"])
    }

    @Test func namesCompareInTheGivenLocale() throws {
        let names = try entries(["Zeh"], ["Öhr"])
        #expect(try counts(report(names, locale: Locale(identifier: "de_DE"))) == ["Öhr 1", "Zeh 1"])
        #expect(try counts(report(names, locale: Locale(identifier: "sv_SE"))) == ["Zeh 1", "Öhr 1"])
    }

    @Test(arguments: [(9, 6, 3), (7, 6, 1), (6, 6, 0), (1, 1, 0)])
    func atMostSixPlacesShowAndTheRestAreCounted(logged: Int, shown: Int, more: Int) throws {
        let names = (1 ... logged).map { "Place \($0)" }
        let places = try report(entries(names))
        #expect(places.shown.count == shown)
        #expect(places.moreCount == more)
    }

    @Test func theSixShownAreTheMostLogged() throws {
        let places = try report(entries(
            ["A", "B", "C", "D", "E", "F", "G"], ["G"], ["F", "G"]
        ))
        #expect(counts(places) == ["G 3", "F 2", "A 1", "B 1", "C 1", "D 1"])
        #expect(places.moreCount == 1)
    }

    @Test func noPlaceLoggedGivesNothingShownAndNoneMore() throws {
        let places = try report(entries([], []))
        #expect(places.shown.isEmpty)
        #expect(places.moreCount == 0)
    }

    @Test func noEntriesGiveNothingShownAndNoneMore() throws {
        let places = try report([])
        #expect(places.shown.isEmpty)
        #expect(places.moreCount == 0)
    }

    @Test func anEntryOnThePeriodsFirstDayCounts() throws {
        let places = try report([entry(at: start, ["Neck"])])
        #expect(counts(places) == ["Neck 1"])
    }

    @Test func anEntryBeforeThePeriodOrAfterNowIsLeftOut() throws {
        let before = try entry(at: start.addingTimeInterval(-1), ["Jaw"])
        let after = try entry(at: now.addingTimeInterval(1), ["Ribs"])
        let places = try report([before, after, entry(at: now, ["Neck"])])
        #expect(counts(places) == ["Neck 1"])
    }

    @Test func aPlaceThisBuildDoesNotKnowIsLeftOut() throws {
        let names = (1 ... 6).map { "Place \($0)" } + ["unknown"]
        let places = try report(entries(names, ["unknown"])) { $0.rawValue == "unknown" ? "" : $0.rawValue }
        #expect(!places.shown.contains { $0.place.rawValue == "unknown" })
        #expect(places.shown.count == 6)
        #expect(places.moreCount == 0)
    }

    @Test func anUnknownPlaceIsNotCountedAmongTheMore() throws {
        let names = (1 ... 7).map { "Place \($0)" } + ["unknown"]
        let places = try report(entries(names)) { $0.rawValue == "unknown" ? "" : $0.rawValue }
        #expect(places.moreCount == 1)
    }
}
