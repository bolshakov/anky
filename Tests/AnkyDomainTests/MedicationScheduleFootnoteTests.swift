// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

private let british = Locale(identifier: "en_GB")

struct MedicationScheduleFootnoteTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> ScheduleDay {
        ScheduleDay(year: year, month: month, day: day)!
    }

    private func moment(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 8) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func schedule(
        _ shape: ScheduleRepeat,
        start: ScheduleDay,
        end: ScheduleDay? = nil
    ) throws -> MedicationSchedule {
        try MedicationSchedule(repeat: shape, times: [#require(DoseTime(hour: 9, minute: 0))], start: start, end: end)
    }

    private func footnote(_ schedule: MedicationSchedule, at now: Date, in locale: Locale) throws -> String {
        let language = locale.language.languageCode?.identifier ?? "en"
        return try CompiledCatalog.withBundle(language) {
            MedicationScheduleLine.footnote(
                schedule: schedule, now: now, locale: locale, calendar: calendar, bundle: $0
            )
        }
    }

    @Test func theWordsAreFollowedByTheNextDoseAsADayAndItsDate() throws {
        let everyTwoWeeks = try schedule(.weeks(2, on: [.friday]), start: day(2026, 11, 13))
        #expect(
            try footnote(everyTwoWeeks, at: moment(2026, 11, 11), in: british)
                == "Every 2 weeks on Friday at 09:00. Next: Friday 13 November."
        )
    }

    @Test(arguments: [(ScheduleRepeat.days(1), "Every day at 09:00. Next: Wednesday 11 November."),
                      (.weeks(1, on: [.friday]), "Every week on Friday at 09:00. Next: Friday 13 November."),
                      (.weeks(4, on: [.friday]), "Every 4 weeks on Friday at 09:00. Next: Friday 13 November."),
                      (.months(1, onDay: 15), "Every month on day 15 at 09:00. Next: Sunday 15 November.")])
    func eachRepeatReadsItsWordsThenItsNextDose(_ shape: ScheduleRepeat, _ sentence: String) throws {
        let schedule = try schedule(shape, start: day(2026, 11, 11))
        #expect(try footnote(schedule, at: moment(2026, 11, 11), in: british) == sentence)
    }

    @Test(arguments: [(ScheduleRepeat.days(1), "Каждый день в 09:00. Следующий приём: Среда, 11 ноября."),
                      (
                          .weeks(1, on: [.friday]),
                          "Каждую неделю: пятница, в 09:00. Следующий приём: Пятница, 13 ноября."
                      ),
                      (
                          .weeks(2, on: [.friday]),
                          "Каждые 2 недели: пятница, в 09:00. Следующий приём: Пятница, 13 ноября."
                      ),
                      (
                          .months(1, onDay: 15),
                          "Каждый месяц 15-го числа в 09:00. Следующий приём: Воскресенье, 15 ноября."
                      )])
    func russianReadsItsWholeSentenceInTheOrderRussianNeeds(_ shape: ScheduleRepeat, _ sentence: String) throws {
        let schedule = try schedule(shape, start: day(2026, 11, 11))
        #expect(try footnote(schedule, at: moment(2026, 11, 11), in: russian) == sentence)
    }

    @Test func aTwelveHourLocaleWritesTheNextDayInItsOwnOrder() throws {
        let schedule = try schedule(.weeks(2, on: [.friday]), start: day(2026, 11, 13))
        let text = try footnote(schedule, at: moment(2026, 11, 11), in: Locale(identifier: "en_US"))
        #expect(text == "Every 2 weeks on Friday at 9:00\u{202F}AM. Next: Friday, November 13.")
    }

    @Test(arguments: [(british, "Every day at 09:00."), (russian, "Каждый день в 09:00.")])
    func withNoNextDoseItReadsTheWordsAndAFullStopOnly(locale: Locale, sentence: String) throws {
        let ended = try schedule(.days(1), start: day(2026, 11, 1), end: day(2026, 11, 5))
        #expect(try footnote(ended, at: moment(2026, 11, 11), in: locale) == sentence)
    }

    @Test func aDayOfTheMonthOf31IsTheLastDayOfAShortMonth() throws {
        let monthly = try schedule(.months(1, onDay: 31), start: day(2026, 1, 31))
        #expect(
            try footnote(monthly, at: moment(2026, 11, 11), in: british)
                == "Every month on day 31 at 09:00. Next: Monday 30 November."
        )
        #expect(
            try footnote(monthly, at: moment(2027, 2, 1), in: british)
                == "Every month on day 31 at 09:00. Next: Sunday 28 February."
        )
    }

    @Test func theNextDoseIsAfterNowSoADoseEarlierTodayIsSkipped() throws {
        let daily = try schedule(.days(1), start: day(2026, 11, 1))
        #expect(
            try footnote(daily, at: moment(2026, 11, 11, 10), in: british)
                == "Every day at 09:00. Next: Thursday 12 November."
        )
    }
}
