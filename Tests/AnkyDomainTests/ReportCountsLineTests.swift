// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

private let british = Locale(identifier: "en_GB")

struct ReportCountsLineTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    private var now: Date {
        get throws { try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 15))) }
    }

    private func entries(_ count: Int, before now: Date) throws -> [Entry] {
        try (0 ..< count).map { index in
            try Entry(
                id: UUID(),
                kind: .pain,
                severity: #require(Severity(4)),
                date: now.addingTimeInterval(-Double(index) * 3600),
                note: nil,
                places: []
            )
        }
    }

    private func doses(_ count: Int, before now: Date) -> [Dose] {
        (0 ..< count).map { index in
            Dose(id: UUID(), medicationID: UUID(), takenAt: now.addingTimeInterval(-Double(index) * 3600))
        }
    }

    private func line(
        entries entryCount: Int,
        doses doseCount: Int,
        period: ReportPeriod,
        in locale: Locale = british
    ) throws -> String {
        let now = try now
        let summary = try ReportSummary(
            entries: entries(entryCount, before: now),
            doses: doses(doseCount, before: now),
            period: period,
            now: now,
            calendar: calendar
        )
        let language = locale.language.languageCode?.identifier ?? "en"
        return try CompiledCatalog.withBundle(language) {
            ReportCountsLine.text(
                summary: summary, period: period, now: now, locale: locale, calendar: calendar, bundle: $0
            )
        }
    }

    @Test func theLineCountsEntriesAndDosesFromThePeriodStartToToday() throws {
        #expect(
            try line(entries: 142, doses: 38, period: .threeMonths)
                == "142 entries and 38 doses, 11 August to 11 November."
        )
    }

    @Test func oneEntryAndOneDoseAreSingular() throws {
        #expect(try line(entries: 1, doses: 1, period: .oneMonth) == "1 entry and 1 dose, 11 October to 11 November.")
    }

    @Test func noDosesReadsZeroDoses() throws {
        #expect(try line(entries: 1, doses: 0, period: .sixMonths) == "1 entry and 0 doses, 11 May to 11 November.")
    }

    @Test func anEmptyPeriodAsksForALongerOne() throws {
        #expect(
            try line(entries: 0, doses: 0, period: .oneMonth)
                == "Nothing logged from 11 October to 11 November. Pick a longer period."
        )
    }

    @Test func dosesAloneAreNotEmpty() throws {
        #expect(try line(entries: 0, doses: 2, period: .oneMonth) ==
            "0 entries and 2 doses, 11 October to 11 November.")
    }

    @Test func theDaysFollowTheRegionsOrder() throws {
        #expect(
            try line(entries: 1, doses: 1, period: .oneMonth, in: Locale(identifier: "en_US"))
                == "1 entry and 1 dose, October 11 to November 11."
        )
    }

    @Test(arguments: [(1, 2, "1 запись и 2 приёма, с 11 октября по 11 ноября."),
                      (5, 21, "5 записей и 21 приём, с 11 октября по 11 ноября.")])
    func russianCountsTakeTheirPluralForms(entries: Int, doses: Int, sentence: String) throws {
        #expect(try line(entries: entries, doses: doses, period: .oneMonth, in: Locale(identifier: "ru")) == sentence)
    }

    @Test func russianEmptyPeriodAsksForALongerOne() throws {
        #expect(
            try line(entries: 0, doses: 0, period: .oneMonth, in: Locale(identifier: "ru"))
                == "С 11 октября по 11 ноября записей нет. Можно выбрать период длиннее."
        )
    }
}
