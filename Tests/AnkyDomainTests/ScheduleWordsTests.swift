// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

private let british = Locale(identifier: "en_GB")
private let american = Locale(identifier: "en_US")
private let nineOClock = [(9, 0)]

struct ScheduleWordsTests {
    /// en_GB and ru write the clock with 24 hours, so they give "09:00". en_US keeps its 12-hour clock.
    @Test(arguments: [(ScheduleRepeat.days(1), [(8, 0)], "Every day at 08:00"),
                      (.days(3), [(8, 0)], "Every 3 days at 08:00"),
                      (.weeks(1, on: [.friday]), nineOClock, "Every week on Friday at 09:00"),
                      (.weeks(2, on: [.friday]), nineOClock, "Every 2 weeks on Friday at 09:00"),
                      (.weeks(4, on: [.tuesday]), nineOClock, "Every 4 weeks on Tuesday at 09:00"),
                      (.months(1, onDay: 15), nineOClock, "Every month on day 15 at 09:00"),
                      (.months(3, onDay: 31), nineOClock, "Every 3 months on day 31 at 09:00")])
    func englishSentence(_ shape: ScheduleRepeat, _ times: [(Int, Int)], _ sentence: String) throws {
        #expect(try words(shape, times, in: british, language: "en") == sentence)
    }

    @Test func severalWeekdaysAndTimesReadAsOneEnglishSentenceListingThemAll() throws {
        let sentence = try words(
            .weeks(2, on: [.friday, .monday, .wednesday]), [(21, 0), (9, 0)], in: british, language: "en"
        )
        #expect(sentence == "Every 2 weeks on Monday, Wednesday and Friday at 09:00 and 21:00")
    }

    @Test func aTwelveHourLocaleKeepsItsTwelveHourClock() throws {
        let sentence = try words(.days(1), [(8, 0), (20, 30)], in: american, language: "en")
        #expect(sentence == "Every day at 8:00\u{202F}AM and 8:30\u{202F}PM")
    }

    @Test(arguments: [(ScheduleRepeat.days(1), [(8, 0)], "Каждый день в 08:00"),
                      (.days(2), [(8, 0)], "Каждые 2 дня в 08:00"),
                      (.days(5), [(8, 0)], "Каждые 5 дней в 08:00"),
                      (.days(21), [(8, 0)], "Каждые 21 день в 08:00")])
    func russianDaySentence(_ shape: ScheduleRepeat, _ times: [(Int, Int)], _ sentence: String) throws {
        #expect(try words(shape, times, in: russian, language: "ru") == sentence)
    }

    @Test(arguments: [(ScheduleRepeat.weeks(1, on: [.friday]), nineOClock, "Каждую неделю: пятница, в 09:00"),
                      (.weeks(2, on: [.friday]), nineOClock, "Каждые 2 недели: пятница, в 09:00"),
                      (.weeks(5, on: [.friday]), nineOClock, "Каждые 5 недель: пятница, в 09:00"),
                      (.weeks(21, on: [.friday]), nineOClock, "Каждые 21 неделю: пятница, в 09:00")])
    func russianWeekSentence(_ shape: ScheduleRepeat, _ times: [(Int, Int)], _ sentence: String) throws {
        #expect(try words(shape, times, in: russian, language: "ru") == sentence)
    }

    @Test(arguments: [(ScheduleRepeat.months(1, onDay: 15), nineOClock, "Каждый месяц 15-го числа в 09:00"),
                      (.months(2, onDay: 3), nineOClock, "Каждые 2 месяца 3-го числа в 09:00"),
                      (.months(5, onDay: 31), nineOClock, "Каждые 5 месяцев 31-го числа в 09:00"),
                      (.months(21, onDay: 1), nineOClock, "Каждые 21 месяц 1-го числа в 09:00")])
    func russianMonthSentence(_ shape: ScheduleRepeat, _ times: [(Int, Int)], _ sentence: String) throws {
        #expect(try words(shape, times, in: russian, language: "ru") == sentence)
    }

    @Test func severalWeekdaysAndTimesReadAsOneRussianSentenceListingThemAll() throws {
        let sentence = try words(
            .weeks(2, on: [.friday, .monday, .wednesday]), [(21, 0), (9, 0)], in: russian, language: "ru"
        )
        #expect(sentence == "Каждые 2 недели: понедельник, среда и пятница, в 09:00 и 21:00")
    }

    @Test func theCalendarsFirstWeekdayDecidesTheOrderOfTheDays() throws {
        let weekend = ScheduleRepeat.weeks(1, on: [.sunday, .saturday])
        var sundayFirst = calendar
        sundayFirst.firstWeekday = 1

        #expect(try words(weekend, nineOClock, in: british, language: "en")
            == "Every week on Saturday and Sunday at 09:00")
        #expect(try words(weekend, nineOClock, in: british, language: "en", calendar: sundayFirst)
            == "Every week on Sunday and Saturday at 09:00")
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    private func words(
        _ repetition: ScheduleRepeat,
        _ times: [(Int, Int)],
        in locale: Locale,
        language: String,
        calendar: Calendar? = nil
    ) throws -> String {
        let schedule = try MedicationSchedule(
            repeat: repetition,
            times: times.compactMap { DoseTime(hour: $0.0, minute: $0.1) },
            start: #require(ScheduleDay(year: 2026, month: 1, day: 5)),
            end: nil
        )
        return try CompiledCatalog.withBundle(language) { bundle in
            schedule.words(locale: locale, calendar: calendar ?? self.calendar, bundle: bundle)
        }
    }
}
