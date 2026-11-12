// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportHeaderLineTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    private func line(
        _ period: ReportPeriod,
        on day: DateComponents,
        in locale: Locale = Locale(identifier: "en_GB")
    ) throws -> String {
        let now = try #require(calendar.date(from: day))
        return try CompiledCatalog.withBundle("en") {
            ReportHeaderLine.text(period: period, now: now, locale: locale, calendar: calendar, bundle: $0)
        }
    }

    private let eleventhOfNovember = DateComponents(year: 2026, month: 11, day: 11, hour: 15)

    @Test func theLineNamesThePeriodItsLengthAndTheDayItWasCreated() throws {
        #expect(
            try line(.threeMonths, on: eleventhOfNovember)
                == "11 August to 11 November 2026 · 3 months · created 11 November 2026"
        )
    }

    @Test(arguments: [(ReportPeriod.oneMonth, "11 October to 11 November 2026 · 1 month"),
                      (.sixMonths, "11 May to 11 November 2026 · 6 months")])
    func eachPeriodNamesItsOwnLength(period: ReportPeriod, start: String) throws {
        #expect(try line(period, on: eleventhOfNovember) == "\(start) · created 11 November 2026")
    }

    @Test func aPeriodThatStartsInTheYearBeforeNamesBothYears() throws {
        #expect(
            try line(.sixMonths, on: DateComponents(year: 2027, month: 2, day: 11, hour: 9))
                == "11 August 2026 to 11 February 2027 · 6 months · created 11 February 2027"
        )
    }

    @Test func theDaysFollowTheRegionsOrder() throws {
        #expect(
            try line(.threeMonths, on: eleventhOfNovember, in: Locale(identifier: "en_US"))
                == "August 11 to November 11, 2026 · 3 months · created November 11, 2026"
        )
    }
}
