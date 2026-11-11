// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

private let wednesday = ScheduleDay(year: 2026, month: 11, day: 11)!
private let nineOClock = DoseTime(hour: 9, minute: 0)!

struct ScheduleDraftTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func stored(_ shape: ScheduleRepeat, start: ScheduleDay = wednesday) throws -> MedicationSchedule {
        try MedicationSchedule(repeat: shape, times: [nineOClock], start: start, end: nil)
    }

    @Test func aNewDraftIsEveryDayAtNineWithNoEnd() throws {
        let draft = ScheduleDraft(startingOn: wednesday, calendar: calendar)
        #expect(draft.preset == .everyDay)
        #expect(draft.times == [nineOClock])
        #expect(draft.start == wednesday)
        #expect(draft.end == nil)
        #expect(try draft.schedule() == stored(.days(1)))
    }

    @Test func aNewDraftTakesTheWeekdayAndTheDayNumberOfItsStart() {
        let draft = ScheduleDraft(startingOn: wednesday, calendar: calendar)
        #expect(draft.weekdays == [.wednesday])
        #expect(draft.dayOfMonth == 11)
    }

    @Test(arguments: [(2026, 11, 8, Locale.Weekday.sunday), (2026, 11, 9, .monday), (2026, 11, 14, .saturday),
                      (2027, 1, 31, .sunday)])
    func theStartingWeekdayIsThatOfTheCalendarDay(
        _ year: Int, _ month: Int, _ day: Int, _ weekday: Locale.Weekday
    ) throws {
        let start = try #require(ScheduleDay(year: year, month: month, day: day))
        #expect(ScheduleDraft(startingOn: start, calendar: calendar).weekdays == [weekday])
    }

    @Test func theStartingWeekdayDoesNotDependOnTheCalendarsTimeZone() throws {
        var kiritimati = calendar
        kiritimati.timeZone = try #require(TimeZone(identifier: "Pacific/Kiritimati"))
        #expect(ScheduleDraft(startingOn: wednesday, calendar: kiritimati).weekdays == [.wednesday])
    }

    @Test(arguments: [(ScheduleRepeat.days(1), ScheduleDraft.Preset.everyDay),
                      (.weeks(1, on: [.wednesday]), .everyWeek),
                      (.weeks(2, on: [.wednesday]), .everyTwoWeeks),
                      (.weeks(4, on: [.wednesday]), .everyFourWeeks)])
    func aStoredScheduleOpensOnThePresetItMatches(_ shape: ScheduleRepeat, _ preset: ScheduleDraft.Preset) throws {
        #expect(try ScheduleDraft(stored(shape), calendar: calendar).preset == preset)
    }

    @Test(arguments: [ScheduleRepeat.days(2), .days(7), .weeks(3, on: [.wednesday]), .weeks(8, on: [.monday]),
                      .months(1, onDay: 11), .months(2, onDay: 11), .months(12, onDay: 1)])
    func aStoredScheduleOutsideTheFourHasNoPreset(_ shape: ScheduleRepeat) throws {
        #expect(try ScheduleDraft(stored(shape), calendar: calendar).preset == nil)
    }

    @Test func theWeekdaysOfAPresetDoNotChangeItsPreset() throws {
        let draft = try ScheduleDraft(stored(.weeks(2, on: [.monday, .friday])), calendar: calendar)
        #expect(draft.preset == .everyTwoWeeks)
    }

    @Test(arguments: [ScheduleRepeat.days(1), .days(3), .weeks(1, on: [.wednesday]),
                      .weeks(3, on: [.monday, .thursday, .sunday]), .weeks(4, on: [.tuesday]),
                      .months(1, onDay: 15), .months(2, onDay: 31)])
    func aDraftOfAStoredScheduleBuildsThatSchedule(_ shape: ScheduleRepeat) throws {
        let schedule = try stored(shape, start: #require(ScheduleDay(year: 2026, month: 12, day: 1)))
        #expect(ScheduleDraft(schedule, calendar: calendar).schedule() == schedule)
    }

    @Test func aDraftKeepsEveryTimeStartAndEndOfTheStoredSchedule() throws {
        let times = try [#require(DoseTime(hour: 21, minute: 30)), nineOClock]
        let end = try #require(ScheduleDay(year: 2027, month: 3, day: 1))
        let schedule = try MedicationSchedule(repeat: .days(1), times: times, start: wednesday, end: end)
        let draft = ScheduleDraft(schedule, calendar: calendar)
        #expect(draft.times == [nineOClock, times[0]])
        #expect(draft.start == wednesday)
        #expect(draft.end == end)
        #expect(draft.schedule() == schedule)
    }

    @Test(arguments: [(ScheduleRepeat.days(2), Locale.Weekday.wednesday, 11),
                      (.months(1, onDay: 20), .wednesday, 20)])
    func aUnitWithNoWeekdaysTakesThemFromTheStartAndOneWithNoDayTakesItFromTheStart(
        _ shape: ScheduleRepeat, _ weekday: Locale.Weekday, _ day: Int
    ) throws {
        let draft = try ScheduleDraft(stored(shape), calendar: calendar)
        #expect(draft.weekdays == [weekday])
        #expect(draft.dayOfMonth == day)
    }

    @Test func aWeeklyScheduleKeepsItsWeekdaysAndTakesTheDayNumberFromItsStart() throws {
        let draft = try ScheduleDraft(stored(.weeks(1, on: [.monday, .friday])), calendar: calendar)
        #expect(draft.weekdays == [.monday, .friday])
        #expect(draft.dayOfMonth == 11)
    }

    @Test(arguments: [(ScheduleDraft.Preset.everyDay, ScheduleRepeat.days(1)),
                      (.everyWeek, .weeks(1, on: [.wednesday])),
                      (.everyTwoWeeks, .weeks(2, on: [.wednesday])),
                      (.everyFourWeeks, .weeks(4, on: [.wednesday]))])
    func choosingAPresetBuildsItsRepeat(_ preset: ScheduleDraft.Preset, _ shape: ScheduleRepeat) throws {
        var draft = ScheduleDraft(startingOn: wednesday, calendar: calendar)
        draft.choose(.everyFourWeeks)
        draft.choose(preset)
        #expect(draft.preset == preset)
        #expect(try draft.schedule() == stored(shape))
    }

    @Test(arguments: ScheduleDraft.Preset.allCases)
    func choosingAPresetReplacesAStoredRepeatOutsideTheFour(_ preset: ScheduleDraft.Preset) throws {
        for shape in [ScheduleRepeat.months(1, onDay: 11), .days(3), .weeks(3, on: [.wednesday])] {
            var draft = try ScheduleDraft(stored(shape), calendar: calendar)
            #expect(draft.preset == nil)
            draft.choose(preset)
            #expect(draft.preset == preset)
        }
    }

    @Test func choosingEveryTwoWeeksShowsItSelectedAndKeepsTheWeekdaysTheDayAndTheTimes() throws {
        let evening = try #require(DoseTime(hour: 21, minute: 0))
        var draft = try ScheduleDraft(stored(.weeks(4, on: [.monday, .friday])), calendar: calendar)
        draft.times = [nineOClock, evening]
        draft.dayOfMonth = 30
        draft.choose(.everyTwoWeeks)
        #expect(draft.preset == .everyTwoWeeks)
        #expect(draft.weekdays == [.monday, .friday])
        #expect(draft.dayOfMonth == 30)
        #expect(draft.times == [nineOClock, evening])
    }

    @Test func choosingAPresetOverAStoredMonthlyScheduleKeepsItsTimes() throws {
        let evening = try #require(DoseTime(hour: 21, minute: 0))
        var draft = try ScheduleDraft(stored(.months(1, onDay: 15)), calendar: calendar)
        draft.times = [nineOClock, evening]
        draft.choose(.everyTwoWeeks)
        #expect(draft.preset == .everyTwoWeeks)
        #expect(draft.times == [nineOClock, evening])
    }

    @Test func aDraftEditedToARepeatOutsideTheFourHasNoPresetAndBuildsIt() throws {
        var draft = ScheduleDraft(startingOn: wednesday, calendar: calendar)
        draft.unit = .weeks
        draft.interval = 3
        #expect(draft.preset == nil)
        #expect(try draft.schedule() == stored(.weeks(3, on: [.wednesday])))
    }

    @Test func aDraftBuildsTheScheduleOfItsOwnUnitWhateverTheOtherFieldsHold() throws {
        var draft = ScheduleDraft(startingOn: wednesday, calendar: calendar)
        draft.weekdays = [.monday, .tuesday]
        draft.dayOfMonth = 4
        draft.interval = 5
        #expect(try draft.schedule() == stored(.days(5)))
        draft.unit = .months
        #expect(try draft.schedule() == stored(.months(5, onDay: 4)))
        draft.unit = .weeks
        #expect(try draft.schedule() == stored(.weeks(5, on: [.monday, .tuesday])))
    }

    @Test func aDraftSortsAndFoldsItsTimesWhenItBuildsTheSchedule() throws {
        var draft = ScheduleDraft(startingOn: wednesday, calendar: calendar)
        let evening = try #require(DoseTime(hour: 21, minute: 0))
        draft.times = [evening, nineOClock, evening]
        #expect(draft.schedule()?.times == [nineOClock, evening])
    }

    @Test func aDraftWithNoTimeBuildsNoSchedule() {
        var draft = ScheduleDraft(startingOn: wednesday, calendar: calendar)
        draft.times = []
        #expect(draft.schedule() == nil)
    }
}
